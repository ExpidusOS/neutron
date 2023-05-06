const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
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

pub fn getFormats(self: *Self) ?*const wlr.DrmFormatSet {
  if (self.value.getPrimaryFormats(8)) |formats| {
    if (formats.len > 0) return formats;
  }
  return self.getCompositor().renderer.getDmabufFormats();
}

fn getBufferDrm(self: *Self) !*wlr.Buffer {
  const res = self.base_output.getResolution();
  const compositor = self.getCompositor();
  if (self.getFormats()) |formats| {
    if (!formats.has(self.value.render_format, 0)) return error.InvalidFormat;
    return if (compositor.allocator.createBuffer(res[0], res[1], formats.get(self.value.render_format))) |buffer| buffer else error.InvalidBuffer;
  }
  return error.MissingDrm;
}

pub fn updateBuffer(self: *Self) !void {
  const buffer = try self.getBufferDrm();

  if (self.fb == null) {
    self.fb = try FrameBuffer.new(.{
      .wlr_buffer = buffer,
    }, null, self.type.allocator);
  } else {
    self.fb.?.buffer.drop();
    self.fb.?.buffer = buffer;
  }

  self.scene_buffer.setBuffer(self.fb.?.buffer);
  try self.subrenderer.toBase().updateFrameBuffer(&self.fb.?.base);
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.type = t;
    self.value = params.value;

    self.base_output = try Output.init(&self.base_output, .{
      .context = params.context,
      .vtable = &vtable,
    }, self, self.type.allocator);

    const compositor = self.getCompositor();
    if (!params.value.initRender(compositor.allocator, compositor.renderer)) return error.RenderFailed;

    if (self.value.preferredMode()) |preferred_mode| {
      self.value.setMode(preferred_mode);
      self.value.enableAdaptiveSync(true);
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

    const old_output = self.base_output;

    self.* = .{
      .type = t,
      .base_output = old_output,
      .value = params.value,
      .fb = null,
      .scene_buffer = try compositor.scene.tree.createSceneBuffer(null),
      .id = try std.fmt.allocPrint(self.type.allocator, "{?s}-{?s}-{?s}-{s}", .{ self.value.serial, self.value.model, self.value.make, self.value.name }),
      .index = compositor.outputs.items.len,
      .subrenderer = try params.context.renderer.toBase().createSubrenderer(self.base_output.getResolution()),
    };

    errdefer self.base_output.unref();
    try self.updateBuffer();
    
    self.value.events.destroy.add(&self.destroy);
    self.value.events.frame.add(&self.frame);
    self.value.events.present.add(&self.present);
    self.value.events.mode.add(&self.mode);
    compositor.output_layout.addAuto(self.value);

    try compositor.outputs.append(self);

    const runtime = compositor.getRuntime();
    if (runtime.engine != null) {
      try runtime.notifyDisplays();
    }

    try self.base_output.sendMetrics(runtime);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_output = undefined,
      .value = self.value,
      .fb = if (self.fb) |fb| try fb.ref(t.allocator) else null,
      .scene_buffer = self.scene_buffer,
      .index = self.index,
      .id = try t.allocator.dupe(u8, self.id),
      .subrenderer = try self.subrenderer.ref(t.allocator),
    };

    _ = try self.base_output.type.refInit(&dest.base_output, t.allocator);
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
subrenderer: graphics.subrenderer.Subrenderer,
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
          std.debug.dumpStackTrace(@errorReturnTrace().?.*);
        };
      }
    }
  }
}).callback),
frame: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "frame", listener);
    const runtime = self.getCompositor().getRuntime();

    const baton = runtime.vsync_baton.swap(0, .AcqRel);
    if (baton != 0) {
      const curr_time = runtime.proc_table.GetCurrentTime.?();
      _ = runtime.proc_table.OnVsync.?(runtime.engine, baton, curr_time, curr_time + 16600000);
    }

    const scene_output = self.getCompositor().scene.getSceneOutput(self.value).?;

    var now: std.os.timespec = undefined;
    std.os.clock_gettime(std.os.CLOCK.MONOTONIC, &now) catch @panic("CLOCK_MONOTONIC not supported");

    if (scene_output.commit()) {
      scene_output.sendFrameDone(&now);

      self.subrenderer.toBase().render() catch |err| {
        std.debug.print("Failed to render: {s}\n", .{ @errorName(err) });
        std.debug.dumpStackTrace(@errorReturnTrace().?.*);
        return;
      };

      self.scene_buffer.sendFrameDone(&now);
    }
  }
}).callback),
present: wl.Listener(*wlr.Output.event.Present) = wl.Listener(*wlr.Output.event.Present).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output.event.Present), event: *wlr.Output.event.Present) void {
    const self = @fieldParentPtr(Self, "present", listener);
    const runtime = self.getCompositor().getRuntime();

    const baton = runtime.vsync_baton.swap(0, .AcqRel);
    if (baton != 0) {
      const curr_time = runtime.proc_table.GetCurrentTime.?();
      const frame_time_ns = @intCast(u64, if (event.refresh == 0) 16600000 else event.refresh);
      _ = runtime.proc_table.OnVsync.?(runtime.engine, baton, curr_time, curr_time + frame_time_ns);
    }
  }
}).callback),
mode: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "mode", listener);

    self.updateBuffer() catch |err| {
      std.debug.print("Failed to update the buffer: {s}\n", .{ @errorName(err) });
      std.debug.dumpStackTrace(@errorReturnTrace().?.*);
      return;
    };

    self.base_output.sendMetrics(self.getCompositor().getRuntime()) catch |err| {
      std.debug.print("Failed to send the metrics: {s}\n", .{ @errorName(err) });
      std.debug.dumpStackTrace(@errorReturnTrace().?.*);
      return;
    };
  }
}).callback),

pub usingnamespace Type.Impl;

pub fn getCompositor(self: *Self) *Compositor {
  return @fieldParentPtr(Compositor, "base_compositor", self.base_output.context.toCompositor());
}
