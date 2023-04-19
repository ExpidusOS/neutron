const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Context = @import("../../base/context.zig");
const Base = @import("../../base/input/base.zig");
const Compositor = @import("../compositor.zig");
const wlr = @import("wlroots");

pub const Params = struct {
  base: *Base,
  device: *wlr.InputDevice,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try params.base.ref(t.allocator),
      .device = params.device,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.ref(t.allocator),
      .device = self.device,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: *Base,
device: *wlr.InputDevice,

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self, comptime T: type) *Compositor {
  return Compositor.Type.fromOpaque(T.Type.fromOpaque(self.type.parent.?.getValue()).type.parent.?.getValue());
}
