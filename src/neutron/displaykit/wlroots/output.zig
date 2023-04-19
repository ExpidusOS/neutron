const std = @import("std");
const elemental = @import("../../elemental.zig");
const Output = @import("../base/output.zig");
const Context = @import("../base/context.zig");
const Compositor = @import("compositor.zig");
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
  self.buffer.init(&.{
    .destroy = (struct {
      fn callback(_: *wlr.Buffer) callconv(.C) void {}
    }).callback,
    .get_dmabuf = (struct {
      fn callback(buffer: *wlr.Buffer, attribs: *wlr.DmabufAttributes) callconv(.C) bool {
        _ = buffer;
        _ = attribs;
        return false;
      }
    }).callback,
    .get_shm = (struct {
      fn callback(buffer: *wlr.Buffer, attribs: *wlr.ShmAttributes) callconv(.C) bool {
        _ = buffer;
        _ = attribs;
        return false;
      }
    }).callback,
    .begin_data_ptr_access = (struct {
      fn callback(buffer: *wlr.Buffer, flags: u32, data: **anyopaque, format: *u32, stride: *usize) callconv(.C) bool {
        _ = flags;

        const that = @fieldParentPtr(Self, "buffer", buffer);
        const fb = that.base_output.subrenderer.toBase().getFrameBuffer() catch {
          return false;
        };

        data.* = fb.getBuffer();
        format.* = fb.getFormat();
        stride.* = fb.getStride();
        return true;
      }
    }).callback,
    .end_data_ptr_access = (struct {
      fn callback(buffer: *wlr.Buffer) callconv(.C) void {
        const that = @fieldParentPtr(Self, "buffer", buffer);
        that.base_output.subrenderer.toBase().commitFrameBuffer() catch |err| {
          std.debug.print("Failed to commit: {}\n", .{ err });
        };
      }
    }).callback,
  }, res[0], res[1]);

  self.scene_buffer.setBuffer(&self.buffer);
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
      .buffer = undefined,
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
      .buffer = self.buffer,
      .scene_buffer = self.scene_buffer,
    };
  }

  pub fn unref(self: *Self) void {
    self.base_output.unref();
    self.value.destroy();
  }

  pub fn destroy(self: *Self) void {
    self.scene_buffer.destroy();
    self.buffer.drop();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_output: Output,
buffer: wlr.Buffer,
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
    const res = self.base_output.getResolution();

    self.base_output.subrenderer.toBase().resize(res) catch |err| {
      std.debug.print("Failed to resize the subrenderer: {s}\n", .{ @errorName(err) });
      return;
      // TODO: use the logger
    };

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
