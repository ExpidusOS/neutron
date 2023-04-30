const std = @import("std");
const elemental = @import("../../elemental.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  context: Context.VTable,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .context = try Context.init(.{
        .vtable = &params.vtable.context,
        .type = .client,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !Self {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = try self.context.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: Context,

pub usingnamespace Type.Impl;
