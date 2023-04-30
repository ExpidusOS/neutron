const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Base = @import("base.zig");
const Keyboard = @import("../../base/input/keyboard.zig");
const Context = @import("../../base/context.zig");
const Compositor = @import("../compositor.zig");
const wlr = @import("wlroots");

pub const Params = struct {
  context: *Context,
  device: *wlr.InputDevice,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base_keyboard = try Keyboard.init(.{
        .context = params.context,
      }, self, self.type.allocator),
      .base = try Base.init(.{
        .base = &self.base_keyboard.base,
        .device = params.device,
      }, self, self.type.allocator),
    };

    const compositor = self.getCompositor();
    compositor.seat.setKeyboard(self.base.device.toKeyboard());
    compositor.seat.setCapabilities(.{
      .pointer = true,
    });
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_keyboard = try self.base_keyboard.type.refInit(t.allocator),
      .base = try self.base.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.base_keyboard.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_keyboard: Keyboard,
base: Base,

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self) *Compositor {
  return self.base.getCompositor(Self);
}
