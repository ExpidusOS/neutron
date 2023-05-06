const std = @import("std");
const elemental = @import("../../elemental.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
};

pub const Params = struct {
  vtable: *const VTable,
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .context = params.context,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = self.context,
    };
  }

  pub fn unref(self: *Self) void {
    _ = self;
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: *Context,

pub usingnamespace Type.Impl;
