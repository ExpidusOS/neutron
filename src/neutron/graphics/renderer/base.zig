const std = @import("std");
const elemental = @import("../../elemental.zig");
const flutter = @import("../../flutter.zig");
const subrenderer = @import("../subrenderer.zig");
const Self = @This();

pub const VTable = struct {
  create_subrenderer: *const fn (self: *anyopaque, res: @Vector(2, i32)) anyerror!subrenderer.Subrenderer,
  get_engine_impl: *const fn (self: *anyopaque) *flutter.c.FlutterRendererConfig,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,

pub usingnamespace Type.Impl;

pub fn createSubrenderer(self: *Self, res: @Vector(2, i32)) !subrenderer.Subrenderer {
  return self.vtable.create_subrenderer(self.type.toOpaque(), res);
}

pub fn getEngineImpl(self: *Self) *flutter.c.FlutterRendererConfig {
  return self.vtable.get_engine_impl(self.type.toOpaque());
}
