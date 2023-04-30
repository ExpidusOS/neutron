const std = @import("std");
const xev = @import("xev");
const elemental = @import("../../../elemental.zig");
const Runtime = @import("../../runtime.zig");
const Self = @This();

pub const VTable = struct {
};

pub const Params = struct {
  vtable: *const VTable,
  runtime: *Runtime,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .runtime = params.runtime,
    };
    errdefer self.loop.deinit();
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .runtime = self.runtime,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
runtime: *Runtime,

pub usingnamespace Type.Impl;
