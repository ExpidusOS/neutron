const std = @import("std");
const wlr = @import("wlroots");
const Compositor = @import("compositor.zig");
const base = @import("../base/input.zig");

pub const Base = @import("input/base.zig");
pub const Keyboard = @import("input/keyboard.zig");
pub const Mouse = @import("input/mouse.zig");
pub const Touch = @import("input/touch.zig");

pub const Input = union(base.Type) {
  keyboard: *Keyboard,
  mouse: *Mouse,
  touch: *Touch,

  pub fn init(device: *wlr.InputDevice, compositor: *Compositor, allocator: ?std.mem.Allocator) !Input {
    return switch (device.type) {
      .keyboard => .{
        .keyboard = try Keyboard.new(.{
          .context = &compositor.base_compositor.context,
          .device = device,
        }, null, allocator),
      },
      .pointer => .{
        .mouse = try Mouse.new(.{
          .context = &compositor.base_compositor.context,
          .device = device,
        }, null, allocator),
      },
      .touch => .{
        .touch = try Touch.new(.{
          .context = &compositor.base_compositor.context,
          .device = device,
        }, null, allocator),
      },
      else => error.Unsupported,
    };
  }

  pub fn ref(self: Input, allocator: ?std.mem.Allocator) !Input {
    return switch (self) {
      .keyboard => |keyboard| .{
        .keyboard = try keyboard.ref(allocator),
      },
      .mouse => |mouse| .{
        .mouse = try mouse.ref(allocator),
      },
      .touch => |touch| .{
        .touch = try touch.ref(allocator),
      },
    };
  }

  pub fn unref(self: Input) void {
    const alloc = self.toBase().toBase().type.allocator;

    try switch (self) {
      .keyboard => |keyboard| keyboard.unref(),
      .mouse => |mouse| mouse.unref(),
      .touch => |touch| touch.unref(),
    };

    alloc.destroy(self);
  }

  pub fn toBase(self: Input) base.Input {
    return switch (self) {
      .keyboard => |keyboard| .{
        .keyboard = &keyboard.base_keyboard,
      },
      .mouse => |mouse| .{
        .mouse = &mouse.base_mouse,
      },
      .touch => |touch| .{
        .touch = &touch.base_touch,
      },
    };
  }
};
