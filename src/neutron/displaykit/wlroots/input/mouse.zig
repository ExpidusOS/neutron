const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const Self = @This();
const Base = @import("base.zig");
const Mouse = @import("../../base/input/mouse.zig");
const Context = @import("../../base/context.zig");
const Compositor = @import("../compositor.zig");

const c = @cImport({
  @cInclude("linux/input-event-codes.h");
});

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
      .btn_mask = 0,
      .acc_btn_mask = 0,
      .acc_scroll_delta = .{ 0, 0 },
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
    self.cursor.events.button.add(&self.button);
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
      .btn_mask = self.btn_mask,
      .acc_btn_mask = self.acc_btn_mask,
      .acc_scroll_delta = .{ 0, 0 },
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

fn processMotion(self: *Self, time: u32, delta_x: f64, delta_y: f64, unaccel_dx: f64, unaccel_dy: f64) void {
  _ = time;
  _ = unaccel_dx;
  _ = unaccel_dy;

  self.cursor.move(self.base.device, delta_x, delta_y);
}

fn uapi2flutter(btn: u32) u32 {
  var mask: u32 = 0;
  if (btn & c.BTN_LEFT == c.BTN_LEFT) mask |= flutter.c.kFlutterPointerButtonMousePrimary;
  if (btn & c.BTN_RIGHT == c.BTN_RIGHT) mask |= flutter.c.kFlutterPointerButtonMouseSecondary;
  if (btn & c.BTN_MIDDLE == c.BTN_MIDDLE) mask |= flutter.c.kFlutterPointerButtonMouseMiddle;
  if (btn & c.BTN_BACK == c.BTN_BACK) mask |= flutter.c.kFlutterPointerButtonMouseBack;
  if (btn & c.BTN_FORWARD == c.BTN_FORWARD) mask |= flutter.c.kFlutterPointerButtonMouseForward;
  return mask;
}

fn flutter2uapi(btn: u32) u32 {
  var mask: u32 = 0;
  if (btn & flutter.c.kFlutterPointerButtonMousePrimary == flutter.c.kFlutterPointerButtonMousePrimary) mask |= c.BTN_LEFT;
  if (btn & flutter.c.kFlutterPointerButtonMouseSecondary == flutter.c.kFlutterPointerButtonMouseSecondary) mask |= c.BTN_RIGHT;
  if (btn & flutter.c.kFlutterPointerButtonMouseMiddle == flutter.c.kFlutterPointerButtonMouseMiddle) mask |= c.BTN_MIDDLE;
  if (btn & flutter.c.kFlutterPointerButtonMouseBack == flutter.c.kFlutterPointerButtonMouseBack) mask |= c.BTN_BACK;
  if (btn & flutter.c.kFlutterPointerButtonMouseForward == flutter.c.kFlutterPointerButtonMouseForward) mask |= c.BTN_FORWARD;
  return mask;
}

@"type": Type,
base_mouse: Mouse,
base: Base,
cursor: *wlr.Cursor,
btn_mask: u32,
acc_btn_mask: u32,
acc_scroll_delta: @Vector(2, f64),
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

    const index: usize = switch (event.orientation) {
      .horizontal => 0,
      .vertical => 1,
    };

    self.acc_scroll_delta[index] += event.delta;
  }
}).callback),
button: wl.Listener(*wlr.Pointer.event.Button) = wl.Listener(*wlr.Pointer.event.Button).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Pointer.event.Button), event: *wlr.Pointer.event.Button) void {
    const self = @fieldParentPtr(Self, "button", listener);

    const fl_button = uapi2flutter(event.button);
    if (fl_button > 0) {
      const mask = @as(u32, 1) << @intCast(u5, fl_button - 1);
      switch (event.state) {
        .pressed => self.acc_btn_mask |= mask,
        .released => self.acc_btn_mask &= ~mask,
        else => {}
      }
    }
  }
}).callback),
frame: wl.Listener(*wlr.Cursor) = wl.Listener(*wlr.Cursor).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Cursor), _: *wlr.Cursor) void {
    const self = @fieldParentPtr(Self, "frame", listener);
    const compositor = self.getCompositor();
    const runtime = compositor.getRuntime();

    compositor.seat.pointerNotifyFrame();

    const last_mask = self.btn_mask;
    const curr_mask = self.acc_btn_mask;

    defer {
      self.acc_scroll_delta = .{ 0, 0 };
      self.btn_mask = curr_mask;
    }

    const event = flutter.c.FlutterPointerEvent {
      .struct_size = @sizeOf(flutter.c.FlutterPointerEvent),
      .phase = if (last_mask == 0 and curr_mask != 0) flutter.c.kDown
        else if (last_mask != 0 and curr_mask == 0) flutter.c.kUp
        else if (curr_mask == 0) flutter.c.kHover
        else flutter.c.kMove,
      .timestamp = runtime.proc_table.GetCurrentTime.?(),
      .x = self.cursor.x,
      .y = self.cursor.y,
      .device = 0,
      .signal_kind = flutter.c.kFlutterPointerSignalKindNone,
      .scroll_delta_x = self.acc_scroll_delta[0],
      .scroll_delta_y = self.acc_scroll_delta[1],
      .device_kind = flutter.c.kFlutterPointerDeviceKindMouse,
      .buttons = curr_mask,
      .pan_x = 0,
      .pan_y = 0,
      .scale = 1.0,
      .rotation = 0.0,
    };

    _ = runtime.proc_table.SendPointerEvent.?(runtime.engine, &event, 1);
  }
}).callback),

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self) *Compositor {
  return self.base.getCompositor();
}
