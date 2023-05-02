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

    compositor.cursor_mngr.setCursorImage("left_ptr", self.cursor);

    self.cursor.events.motion.add(&self.motion);
    self.cursor.events.motion_absolute.add(&self.motion_abs);
    self.cursor.events.axis.add(&self.axis);
    self.cursor.events.frame.add(&self.frame);

    var caps = @bitCast(wl.Seat.Capability, compositor.seat.capabilities);
    caps.pointer = true;
    compositor.seat.setCapabilities(caps);
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

fn processMotion(self: *Self, time: u32, delta_x: f64, delta_y: f64, unaccel_dx: f64, unaccel_dy: f64) void {
  _ = time;
  _ = unaccel_dx;
  _ = unaccel_dy;

  self.cursor.move(self.base.device, delta_x, delta_y);
}

@"type": Type,
base_mouse: Mouse,
base: Base,
cursor: *wlr.Cursor,
motion: wl.Listener(*wlr.Pointer.event.Motion) = wl.Listener(*wlr.Pointer.event.Motion).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.Motion), event: *wlr.Pointer.event.Motion) void {
    const self = @fieldParentPtr(Self, "motion", listener);
    self.processMotion(event.time_msec, event.delta_x, event.delta_y, event.unaccel_dx, event.unaccel_dy);
  }
}).callback),
motion_abs: wl.Listener(*wlr.Pointer.event.MotionAbsolute) = wl.Listener(*wlr.Pointer.event.MotionAbsolute).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.MotionAbsolute), event: *wlr.Pointer.event.MotionAbsolute) void {
    const self = @fieldParentPtr(Self, "motion_abs", listener);

    var lx: f64 = undefined;
    var ly: f64 = undefined;
    self.cursor.absoluteToLayoutCoords(event.device, event.x, event.y, &lx, &ly);

    const dx = lx - self.cursor.x;
    const dy = ly - self.cursor.y;
    self.processMotion(event.time_msec, dx, dx, dx, dy);
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

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self) *Compositor {
  return self.base.getCompositor(Self);
}
