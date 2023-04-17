const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Base = @import("base.zig");
const Self = @This();

const c = @cImport({
  @cInclude("EGL/egl.h");
});

pub const VTable = struct {
  base: Base.VTable,
  get_egl_display: *const fn (self: *anyopaque) c.EGLDisplay,
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

pub inline fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return Type.init(params, parent, allocator);
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}

pub inline fn getEglDisplay(self: *Self) c.EGLDisplay {
  return self.vtable.get_egl_display(self.type.toOpaque());
}
