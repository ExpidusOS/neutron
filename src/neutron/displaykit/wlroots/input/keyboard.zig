const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Base = @import("base.zig");
const Keyboard = @import("../../base/input/keyboard.zig");
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
      .base_keyboard = try Keyboard.init(&self.base_keyboard, .{
        .context = params.context,
      }, self, self.type.allocator),
      .base = try Base.init(&self.base, .{
        .base = &self.base_keyboard.base,
        .device = params.device,
      }, self, self.type.allocator),
    };

    const compositor = self.getCompositor();

    var caps = @bitCast(wl.Seat.Capability, compositor.seat.capabilities);
    caps.keyboard = true;
    compositor.seat.setCapabilities(caps);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_keyboard = undefined,
      .base = undefined,
    };

    _ = try self.base_keyboard.type.refInit(&dest.base_keyboard, t.allocator);
    _ = try self.base.type.refInit(&dest.base, t.allocator);
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
  return self.base.getCompositor();
}
