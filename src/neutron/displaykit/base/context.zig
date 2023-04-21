const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const hardware = @import("../../hardware.zig");
const Compositor = @import("compositor.zig");
const Client = @import("client.zig");
const base = @import("base.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Self = @This();

pub const EGLImageKHRParameters = struct {
  target: c_uint,
  buffer: ?*anyopaque,
  attribs: []i32,
};

/// Virtual function table
pub const VTable = struct {
  get_egl_image_khr_parameters: ?*const fn (self: *anyopaque, fb: *graphics.FrameBuffer) anyerror!EGLImageKHRParameters = null,
};

pub const Params = struct {
  @"type": base.Type,
  renderer: ?graphics.renderer.Params,
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
      .renderer = try graphics.renderer.Renderer.init(params.renderer, params.gpu, self, t.allocator),
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
    return error.NoRef;
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

pub fn getEGLImageKHRParameters(self: *Self, fb: *graphics.FrameBuffer) !EGLImageKHRParameters {
  if (self.vtable.get_egl_image_khr_parameters) |get_egl_image_khr_parameters| {
    return get_egl_image_khr_parameters(self.type.toOpaque(), fb);
  }
  return error.NotImplemented;
}
