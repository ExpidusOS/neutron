const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const Self = @This();
const Mouse = @import("../../base/input/mouse.zig");
const Context = @import("../../base/context.zig");
const Client = @import("../client.zig");

const wl = @import("wayland").client.wl;

pub const Params = struct {
  context: *Context,
  value: *wl.Pointer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .value = params.value,
      .base_mouse = undefined,
    };

    _ = try Mouse.init(&self.base_mouse, .{
      .context = params.context,
    }, self, self.type.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .value = self.value,
      .base_mouse = undefined,
    };

    _ = try self.base_mouse.type.refInit(&dest.base_mouse, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base_touch.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
value: *wl.Pointer,
base_mouse: Mouse,

pub usingnamespace Type.Impl;
