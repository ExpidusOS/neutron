const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const hardware = @import("../../hardware.zig");
const Compositor = @import("compositor.zig");
const Client = @import("client.zig");
const base = @import("base.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Self = @This();

/// Virtual function table
pub const VTable = struct {
  create_render_surface: *const fn (self: *anyopaque, res: @Vector(2, i32), visual: u32) anyerror!*anyopaque,
  resize_render_surface: *const fn (self: *anyopaque, surf: *anyopaque, res: @Vector(2, i32)) anyerror!void,
  get_render_surface_buffer: *const fn (self: *anyopaque, surf: *anyopaque) anyerror!*graphics.FrameBuffer,
  commit_render_surface_buffer: *const fn (self: *anyopaque, surf: *anyopaque, fb: *graphics.FrameBuffer) anyerror!void,
  destroy_render_surface: *const fn (self: *anyopaque, surf: *anyopaque) void,
};

pub const Params = struct {
  @"type": base.Type,
  gpu: ?*hardware.device.Gpu,
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      ._type = params.type,
      .vtable = params.vtable,
      .gpu = if (params.gpu) |gpu| try gpu.ref(t.allocator) else null,
      .renderer = try graphics.renderer.Renderer.init(.{
        .gpu = params.gpu,
        .displaykit = self,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      ._type = self._type,
      .vtable = self.vtable,
      .gpu = if (self.gpu) |gpu| try gpu.ref(t.allocator) else null,
      .renderer = self.renderer,
    };
  }

  pub fn unref(self: *Self) void {
    if (self.gpu) |gpu| {
      gpu.unref();
    }
  }

  pub fn destroy(self: *Self) void {
    self.renderer.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
_type: base.Type,
vtable: *const VTable,
gpu: ?*hardware.device.Gpu = null,
renderer: graphics.renderer.Renderer,

pub usingnamespace Type.Impl;

pub fn toCompositor(self: *Self) *Compositor {
  if (self._type != .compositor) @panic("Cannot cast a client to a compositor");
  return Compositor.Type.fromOpaque(self.type.parent.?);
}

pub fn toClient(self: *Self) *Client {
  if (self._type != .client) @panic("Cannot cast a compositor to a client");
  return Client.Type.fromOpaque(self.type.parent.?);
}

pub fn createRenderSurface(self: *Self, res: @Vector(2, i32), visual: u32) !*anyopaque {
  return self.vtable.create_render_surface(self.type.toOpaque(), res, visual);
}

pub fn resizeRenderSurface(self: *Self, surf: *anyopaque, res: @Vector(2, i32)) !void {
  return self.vtable.resize_render_surface(self.type.toOpaque(), surf, res);
}

pub fn getRenderSurfaceBuffer(self: *Self, surf: *anyopaque) !*graphics.FrameBuffer {
  return self.vtable.get_render_surface_buffer(self.type.toOpaque(), surf);
}

pub fn commitRenderSurfaceBuffer(self: *Self, surf: *anyopaque, fb: *graphics.FrameBuffer) !void {
  return self.vtable.commit_render_surface_buffer(self.type.toOpaque(), surf, fb);
}

pub fn destroyRenderSurface(self: *Self, surf: *anyopaque) void {
  return self.vtable.destroy_render_surface(self.type.toOpaque(), surf);
}
