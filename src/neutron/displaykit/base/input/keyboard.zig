const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Base = @import("base.zig");
const Context = @import("../context.zig");

pub const Params = struct {
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Base.init(.{
        .context = params.context,
      }, self, self.type.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,

pub usingnamespace Type.Impl;

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}
