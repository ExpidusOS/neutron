const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Base = @import("base.zig");
const Self = @This();

const c = @cImport({
  @cInclude("EGL/egl.h");
});

pub const VTable = struct {
  base: Base.VTable,
  get_egl_display: *const fn (self: *anyopaque) anyerror!c.EGLDisplay,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .base = try Base.init(.{
        .vtable = &params.vtable.base,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .base = try self.base.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
base: Base,

pub usingnamespace Type.Impl;

pub inline fn getEglDisplay(self: *Self) !c.EGLDisplay {
  return self.vtable.get_egl_display(self.type.toOpaque());
}
