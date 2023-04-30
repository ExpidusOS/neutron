const std = @import("std");
const elemental = @import("../../elemental.zig");
const displaykit = @import("../../displaykit.zig");
const hardware = @import("../../hardware.zig");
const api = @import("../api/osmesa.zig");
const Base = @import("base.zig");
const Self = @This();

const c = api.c;

pub const Params = struct {};

const Impl = struct {
  pub fn construct(self: *Self, _: Params, t: Type) !void {
    _ = self;
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

pub fn getDisplayKit(self: *Self) ?*displaykit.base.Context {
  _ = self;
  return null;
}
