const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Context = @import("../context.zig");

pub const Params = struct {
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .context = try params.context.ref(t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .context = try self.context.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
context: *Context,

pub usingnamespace Type.Impl;

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}
