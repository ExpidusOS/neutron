const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Base = @import("base.zig");
const Touch = @import("../../base/input/touch.zig");
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
      .base_touch = try Touch.init(&self.base_touch, .{
        .context = params.context,
      }, self, self.type.allocator),
      .base = try Base.init(&self.base, .{
        .base = &self.base_touch.base,
        .device = params.device,
      }, self, self.type.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_touch = undefined,
      .base = undefined,
    };

    _ = try self.base_touch.type.refInit(&dest.base_touch, t.allocator);
    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.base_touch.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_touch: Touch,
base: Base,

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self) *Compositor {
  return self.base.getCompositor(Self);
}
