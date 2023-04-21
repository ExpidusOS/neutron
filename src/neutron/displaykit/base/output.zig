const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  get_resolution: *const fn (self: *anyopaque) @Vector(2, i32),
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
      .subrenderer = try params.context.renderer.toBase().createSubrenderer(self.getResolution()),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = self.context,
      .subrenderer = try self.subrenderer.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.subrenderer.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: *Context,
subrenderer: graphics.subrenderer.Subrenderer,

pub usingnamespace Type.Impl;

pub fn getResolution(self: *Self) @Vector(2, i32) {
  return self.vtable.get_resolution(self.type.toOpaque());
}
