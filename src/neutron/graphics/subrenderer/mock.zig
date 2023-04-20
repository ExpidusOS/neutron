const std = @import("std");
const elemental = @import("../../elemental.zig");
const Base = @import("base.zig");
const Self = @This();

pub const Params = struct {};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    _ = self;
    _ = params;
    _ = t;
    return error.Unsupported;
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    _ = self;
    _ = dest;
    _ = t;
    return error.Unsupported;
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,

pub usingnamespace Type.Impl;
