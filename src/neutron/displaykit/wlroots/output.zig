const std = @import("std");
const elemental = @import("../../elemental.zig");
const Output = @import("../base/output.zig");
const Context = @import("../base/context.zig");
const Compositor = @import("compositor.zig");
const FrameBuffer = @import("fb.zig");
const Self = @This();
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {
  context: *Context,
  value: *wlr.Output,
};

const vtable = Output.VTable {
  .get_resolution = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());

      if (self.value.current_mode) |mode| {
        return @Vector(2, i32) { mode.width, mode.height };
      }
      return @Vector(2, i32) { self.value.width, self.value.height };
    }
  }).callback,
  .get_position = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      const compositor = self.getCompositor();

      const ol = compositor.output_layout.get(self.value) orelse return @Vector(2, i32) { 0, 0 };
      return @Vector(2, i32) {
        ol.x,
        ol.y,
      };
    }
  }).callback,
  .get_scale = (struct {
    fn callback(_base: *anyopaque) f32 {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.value.scale;
    }
  }).callback,
  .get_physical_size = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return @Vector(2, i32) {
        self.value.phys_width,
        self.value.phys_height,
      };
    }
  }).callback,
  .get_refresh_rate = (struct {
    fn callback(_base: *anyopaque) i32 {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return if (self.value.current_mode) |mode| mode.refresh else self.value.refresh;
    }
  }).callback,
  .get_id = (struct {
    fn callback(_base: *anyopaque) u32 {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return std.hash.CityHash32.hash(self.id);
    }
  }).callback,
};

fn effectiveResTry(self: *Self) bool {
  var width: c_int = undefined;
  var height: c_int = undefined;
  self.value.effectiveResolution(&width, &height);

  const rates = [_]i32 { 64, 32, 24, 16, 8, 4, 2 };
  for (rates) |rate| {
    self.value.setCustomMode(width, height, rate);
    self.value.enable(true);
    self.value.commit() catch continue;
    return true;
  }
  return false;
}

fn iterateResTry(self: *Self) bool {
  var it = self.value.modes.iterator(.forward);
  while (it.next()) |mode| {
    self.value.setMode(mode);
    self.value.enable(true);
    self.value.commit() catch continue;
    return true;
  }
  return false;
}

pub fn updateBuffer(self: *Self) !void {
  const res = self.base_output.getResolution();
  const compositor = self.getCompositor();
  const formats = compositor.renderer.getDmabufFormats();
  if (!formats.has(self.value.render_format, 0)) return error.InvalidFormat;

  const buffer = try (if (compositor.allocator.createBuffer(res[0], res[1], formats.get(self.value.render_format))) |buffer| buffer else error.InvalidBuffer);

  if (self.fb == null) {
    self.fb = try FrameBuffer.new(.{
      .wlr_buffer = buffer,
    }, null, self.type.allocator);
  } else {
    self.fb.?.buffer.drop();
    self.fb.?.buffer = buffer;
  }

  self.scene_buffer.setBuffer(self.fb.?.buffer);
  try self.base_output.subrenderer.toBase().updateFrameBuffer(&self.fb.?.base);
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.type = t;
    self.value = params.value;

    const compositor = self.getCompositor();
    if (!params.value.initRender(compositor.allocator, compositor.renderer)) return error.RenderFailed;

    if (self.value.preferredMode()) |preferred_mode| {
      self.value.setMode(preferred_mode);
      self.value.enable(true);
      self.value.commit() catch {
        if (!iterateResTry(self)) {
          _ = effectiveResTry(self);
        }
      };
    } else {
      if (!iterateResTry(self)) {
        _ = effectiveResTry(self);
      }
    }

    self.* = .{
      .type = t,
      .base_output = try Output.init(.{
        .context = params.context,
        .vtable = &vtable,
      }, self, self.type.allocator),
      .value = params.value,
      .fb = null,
      .scene_buffer = try compositor.scene.tree.createSceneBuffer(null),
      .id = try std.fmt.allocPrint(self.type.allocator, "{?s}-{?s}-{?s}-{s}", .{ self.value.serial, self.value.model, self.value.make, self.value.name }),
      .index = compositor.outputs.items.len,
    };

    errdefer self.base_output.unref();
    try self.updateBuffer();
    
    self.value.events.destroy.add(&self.destroy);
    self.value.events.frame.add(&self.frame);
    self.value.events.mode.add(&self.mode);
    compositor.output_layout.addAuto(self.value);

    try compositor.outputs.append(self);

    const runtime = compositor.getRuntime();
    if (runtime.engine != null) {
      try runtime.notifyDisplays();
    }
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_output = try self.base_output.type.refInit(t.allocator),
      .value = self.value,
      .fb = if (self.fb) |fb| try fb.ref(t.allocator) else null,
      .scene_buffer = self.scene_buffer,
      .index = self.index,
      .id = try t.allocator.dupe(u8, self.id),
    };
  }

  pub fn unref(self: *Self) void {
    self.base_output.unref();

    if (self.fb) |fb| {
      // FIXME: segment faults
      // fb.unref();
      _ = fb;
      self.fb = null;
    }

    self.type.allocator.free(self.id);
  }

  pub fn destroy(self: *Self) void {
    self.value.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_output: Output,
fb: ?*FrameBuffer,
value: *wlr.Output,
scene_buffer: *wlr.SceneBuffer,
id: []const u8,
index: usize,
destroy: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "destroy", listener);

    const compositor = self.getCompositor();
    const runtime = compositor.getRuntime();

    if (compositor.outputs.remove(self.index)) |s| {
      s.unref();

      if (runtime.engine != null) {
        runtime.notifyDisplays() catch |err| {
          std.debug.print("Failed to update displays: {s}\n", .{ @errorName(err) });
        };
      }
    }
  }
}).callback),
frame: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "frame", listener);

    self.base_output.subrenderer.toBase().render() catch |err| {
      std.debug.print("Failed to render: {s}\n", .{ @errorName(err) });
      return;
    };

    const scene_output = self.getCompositor().scene.getSceneOutput(self.value).?;
    _ = scene_output.commit();

    var now: std.os.timespec = undefined;
    std.os.clock_gettime(std.os.CLOCK.MONOTONIC, &now) catch @panic("CLOCK_MONOTONIC not supported");
    scene_output.sendFrameDone(&now);
  }
}).callback),
mode: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "mode", listener);
    self.updateBuffer() catch |err| {
      std.debug.print("Failed to update the buffer: {s}\n", .{ @errorName(err) });
      return;
    };
  }
}).callback),

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self) *Compositor {
  return Compositor.Type.fromOpaque(self.type.parent.?.getValue());
}
