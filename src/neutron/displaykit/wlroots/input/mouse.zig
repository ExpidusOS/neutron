const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Base = @import("base.zig");
const Mouse = @import("../../base/input/mouse.zig");
const Context = @import("../../base/context.zig");
const Compositor = @import("../compositor.zig");

const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {
  context: *Context,
  device: *wlr.InputDevice,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base_mouse = try Mouse.init(.{
        .context = params.context,
      }, self, self.type.allocator),
      .base = try Base.init(.{
        .base = &self.base_mouse.base,
        .device = params.device,
      }, self, self.type.allocator),
      .cursor = try wlr.Cursor.create(),
    };

    const compositor = self.getCompositor();
    self.cursor.attachOutputLayout(compositor.output_layout);
    self.cursor.attachInputDevice(self.base.device);

    self.cursor.events.motion.add(&self.motion);
    self.cursor.events.motion_absolute.add(&self.motion_abs);
    self.cursor.events.axis.add(&self.axis);
    self.cursor.events.frame.add(&self.frame);

    compositor.seat.setCapabilities(.{
      .pointer = true,
    });
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_mouse = try self.base_mouse.type.refInit(t.allocator),
      .base = try self.base.type.refInit(t.allocator),
      .cursor = self.cursor,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.base_mouse.unref();
    self.cursor.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_mouse: Mouse,
base: Base,
cursor: *wlr.Cursor,
motion: wl.Listener(*wlr.Pointer.event.Motion) = wl.Listener(*wlr.Pointer.event.Motion).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.Motion), event: *wlr.Pointer.event.Motion) void {
    const self = @fieldParentPtr(Self, "motion", listener);
    self.cursor.move(event.device, event.delta_x, event.delta_y);
  }
}).callback),
motion_abs: wl.Listener(*wlr.Pointer.event.MotionAbsolute) = wl.Listener(*wlr.Pointer.event.MotionAbsolute).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.MotionAbsolute), event: *wlr.Pointer.event.MotionAbsolute) void {
    const self = @fieldParentPtr(Self, "motion_abs", listener);
    self.cursor.warpAbsolute(event.device, event.x, event.y);
  }
}).callback),
axis: wl.Listener(*wlr.Pointer.event.Axis) = wl.Listener(*wlr.Pointer.event.Axis).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.Axis), event: *wlr.Pointer.event.Axis) void {
    const self = @fieldParentPtr(Self, "axis", listener);
    self.getCompositor().seat.pointerNotifyAxis(event.time_msec, event.orientation, event.delta, event.delta_discrete, event.source);
  }
}).callback),
frame: wl.Listener(*wlr.Cursor) = wl.Listener(*wlr.Cursor).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Cursor), _: *wlr.Cursor) void {
    const self = @fieldParentPtr(Self, "frame", listener);
    self.getCompositor().seat.pointerNotifyFrame();
  }
}).callback),

pub inline fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return Type.init(params, parent, allocator);
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}

pub inline fn getCompositor(self: *Self) *Compositor {
  return self.base.getCompositor(Self);
}
