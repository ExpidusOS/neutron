const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const flutter = @import("../../flutter.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  get_resolution: *const fn (self: *anyopaque) @Vector(2, i32),
  get_position: *const fn (self: *anyopaque) @Vector(2, i32),
  get_scale: *const fn (self: *anyopaque) f32,
  get_physical_size: *const fn (self: *anyopaque) @Vector(2, i32),
  get_refresh_rate: *const fn (self: *anyopaque) i32,
  get_id: *const fn (self: *anyopaque) u32,
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

pub fn getPosition(self: *Self) @Vector(2, i32) {
  return self.vtable.get_position(self.type.toOpaque());
}

pub fn getScale(self: *Self) f32 {
  return self.vtable.get_scale(self.type.toOpaque());
}

pub fn getPhysicalSize(self: *Self) @Vector(2, i32) {
  return self.vtable.get_physical_size(self.type.toOpaque());
}

pub fn getRefreshRate(self: *Self) i32 {
  return self.vtable.get_refresh_rate(self.type.toOpaque());
}

pub fn getId(self: *Self) u32 {
  return self.vtable.get_id(self.type.toOpaque());
}

pub fn notifyFlutter(self: *Self, runtime: *Runtime) !void {
  _ = self;
  _ = runtime;
}
