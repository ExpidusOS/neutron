const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  context: Context.VTable,
};

pub const Params = struct {
  vtable: *const VTable,
  gpu: ?*hardware.device.Gpu,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .context = try Context.init(.{
        .vtable = &params.vtable.context,
        .gpu = params.gpu,
        .type = .compositor,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = try self.context.ref(t.allocator),
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
