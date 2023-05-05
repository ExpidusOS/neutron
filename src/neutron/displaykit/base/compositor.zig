const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const graphics = @import("../../graphics.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  context: Context.VTable,
};

pub const Params = struct {
  vtable: *const VTable,
  renderer: ?graphics.renderer.Params,
  gpu: ?*hardware.base.device.Gpu,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .context = undefined,
    };

    _ = try Context.init(&self.context, .{
      .vtable = &params.vtable.context,
      .renderer = params.renderer,
      .gpu = params.gpu,
      .type = .compositor,
    }, self, t.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = undefined,
    };

    _ = try self.context.type.refInit(&self.context);
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
