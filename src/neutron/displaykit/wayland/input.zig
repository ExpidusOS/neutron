const std = @import("std");
const Client = @import("client.zig");
const base = @import("../base/input.zig");

pub const Keyboard = @import("input/keyboard.zig");
pub const Mouse = @import("input/mouse.zig");
pub const Touch = @import("input/touch.zig");

pub const Input = union(base.Type) {
  keyboard: *Keyboard,
  mouse: *Mouse,
  touch: *Touch,

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
    return switch (self) {
      .keyboard => |keyboard| keyboard.unref(),
      .mouse => |mouse| mouse.unref(),
      .touch => |touch| touch.unref(),
    };
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
