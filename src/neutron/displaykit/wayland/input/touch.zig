const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const Self = @This();
const Touch = @import("../../base/input/touch.zig");
const Context = @import("../../base/context.zig");
const Client = @import("../client.zig");

const wl = @import("wayland").client.wl;

pub const Params = struct {
  context: *Context,
  value: *wl.Touch,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .value = params.value,
      .base_touch = undefined,
    };

    _ = try Touch.init(&self.base_touch, .{
      .context = params.context,
    }, self, self.type.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .value = self.value,
      .base_touch = undefined,
    };

    _ = try self.base_touch.type.refInit(&dest.base_touch, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base_touch.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
value: *wl.Touch,
base_touch: Touch,

pub usingnamespace Type.Impl;
