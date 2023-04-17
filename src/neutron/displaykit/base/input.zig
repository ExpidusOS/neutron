const std = @import("std");

pub const Base = @import("input/base.zig");
pub const Keyboard = @import("input/keyboard.zig");
pub const Mouse = @import("input/mouse.zig");
pub const Touch = @import("input/touch.zig");

pub const Type = enum {
  keyboard,
  mouse,
  touch
};

pub const Input = union(Type) {
  keyboard: *Keyboard,
  mouse: *Mouse,
  touch: *Touch,

  pub fn ref(self: *Input, allocator: ?std.mem.Allocator) !Input {
    return switch (self.*) {
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

  pub fn unref(self: *Input) void {
    return switch (self.*) {
      .keyboard => |keyboard| keyboard.unref(),
      .mouse => |mouse| mouse.unref(),
      .touch => |touch| touch.unref(),
    };
  }

  pub fn toBase(self: *Input) *Base {
    return switch (self.*) {
      .keyboard => |keyboard| &keyboard.base,
      .mouse => |mouse| &mouse.base,
      .touch => |touch| &touch.base,
    };
  }
};
