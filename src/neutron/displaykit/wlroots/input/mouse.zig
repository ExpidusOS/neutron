const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
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
      .base_mouse = undefined,
      .base = undefined,
      .cursor = try wlr.Cursor.create(),
    };

    _ = try Mouse.init(&self.base_mouse, .{
      .context = params.context,
    }, self, self.type.allocator);

    _ = try Base.init(&self.base, .{
      .base = &self.base_mouse.base,
      .device = params.device,
    }, self, self.type.allocator);

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
      .base_mouse = undefined,
      .base = undefined,
      .cursor = self.cursor,
    };

    _ = try self.base_mouse.type.refInit(&dest.base_mouse, t.allocator);
    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.base_mouse.unref();
    self.cursor.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

fn processMotion(self: *Self, time: u32, delta_x: f64, delta_y: f64, unaccel_dx: f64, unaccel_dy: f64) !void {
  _ = unaccel_dx;
  _ = unaccel_dy;

  self.cursor.move(self.base.device, delta_x, delta_y);

  const compositor = self.getCompositor();
  const runtime = compositor.getRuntime();

  const events = &[_]flutter.c.FlutterPointerEvent {
    .{
      .struct_size = @sizeOf(flutter.c.FlutterPointerEvent),
      .phase = flutter.c.kHover,
      .timestamp = time,
      .x = self.cursor.x,
      .y = self.cursor.y,
      .device = 0,
      .signal_kind = flutter.c.kFlutterPointerSignalKindNone,
      .scroll_delta_x = 0,
      .scroll_delta_y = 0,
      .device_kind = flutter.c.kFlutterPointerDeviceKindMouse,
      .buttons = 0,
      .pan_x = 0,
      .pan_y = 0,
      .scale = 1.0,
      .rotation = 0.0,
    },
  };

  const result = runtime.proc_table.SendPointerEvent.?(runtime.engine, &events[0], events.*.len);
  if (result != flutter.c.kSuccess) return error.EngineFail;
}

@"type": Type,
base_mouse: Mouse,
base: Base,
cursor: *wlr.Cursor,
motion: wl.Listener(*wlr.Pointer.event.Motion) = wl.Listener(*wlr.Pointer.event.Motion).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.Motion), event: *wlr.Pointer.event.Motion) void {
    const self = @fieldParentPtr(Self, "motion", listener);
    self.processMotion(event.time_msec, event.delta_x, event.delta_y, event.unaccel_dx, event.unaccel_dy) catch |err| {
      std.debug.print("Failed to process pointer motion: {s}\n", .{ @errorName(err) });
    };
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
    self.processMotion(event.time_msec, dx, dx, dx, dy) catch |err| {
      std.debug.print("Failed to process pointer motion: {s}\n", .{ @errorName(err) });
    };
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
  return self.base.getCompositor();
}
