const std = @import("std");
const elemental = @import("../../elemental.zig");
const FrameBuffer = @import("../fb.zig");
const Renderer = @import("../renderer/base.zig");
const Self = @This();

pub const VTable = struct {
  update_frame_buffer: ?*const fn (self: *anyopaque, fb: *FrameBuffer) anyerror!void = null,
  update_surface: ?*const fn (self: *anyopaque, surf: *anyopaque, res: @Vector(2, i32)) anyerror!void = null,
};

pub const Params = struct {
  vtable: *const VTable,
  renderer: *Renderer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .renderer = try params.renderer.ref(t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .renderer = try self.renderer.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.renderer.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
renderer: *Renderer,

pub usingnamespace Type.Impl;

pub fn updateFrameBuffer(self: *Self, fb: *FrameBuffer) !void {
  if (self.vtable.update_frame_buffer) |update_frame_buffer| {
    return update_frame_buffer(self.type.toOpaque(), fb);
  }
  return error.NotImplemented;
}

pub fn updateSurface(self: *Self, surf: *anyopaque, res: @Vector(2, i32)) !void {
  if (self.vtable.update_surface) |update_surface| {
    return update_surface(self.type.toOpaque(), surf, res);
  }
  return error.NotImplemented;
}
