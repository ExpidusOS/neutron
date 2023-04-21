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
    };

    errdefer self.base_output.unref();
    try self.updateBuffer();
    
    self.value.events.frame.add(&self.frame);
    self.value.events.mode.add(&self.mode);
    compositor.output_layout.addAuto(self.value);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_output = try self.base_output.type.refInit(t.allocator),
      .value = self.value,
      .fb = if (self.fb) |fb| try fb.ref(t.allocator) else null,
      .scene_buffer = self.scene_buffer,
    };
  }

  pub fn unref(self: *Self) void {
    self.base_output.unref();
    self.value.destroy();

    if (self.fb) |fb| {
      fb.unref();
    }
  }

  pub fn destroy(self: *Self) void {
    self.scene_buffer.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_output: Output,
fb: ?*FrameBuffer,
value: *wlr.Output,
scene_buffer: *wlr.SceneBuffer,
frame: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "frame", listener);

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
