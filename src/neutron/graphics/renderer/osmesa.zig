const std = @import("std");
const elemental = @import("../../elemental.zig");
const displaykit = @import("../../displaykit.zig");
const hardware = @import("../../hardware.zig");
const api = @import("../api/osmesa.zig");
const Base = @import("base.zig");
const Self = @This();

const c = api.c;

const Impl = struct {
  pub fn construct(self: *Self, _: Base.CommonParams, t: Type) !void {
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

pub const Type = elemental.Type(Self, Base.CommonParams, Impl);

@"type": Type,
base: Base,

pub usingnamespace Type.Impl;

pub fn getDisplayKit(self: *Self) ?*displaykit.base.Context {
  _ = self;
  return null;
}
