const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Runtime = @import("../../runtime.zig");
const Base = @import("base.zig");
const Self = @This();

pub const Params = struct {
  runtime: *Runtime,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Base.init(&self.base, .{
        .vtable = &.{},
        .runtime = params.runtime,
      }, self, self.type.allocator),
    };
  }

  pub fn ref(self: *Self, t: Type) !Self {
    return .{
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
