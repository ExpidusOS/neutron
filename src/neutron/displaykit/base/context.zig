const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const Compositor = @import("compositor.zig");
const Client = @import("client.zig");
const base = @import("base.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Self = @This();

const c = @cImport({
  @cInclude("EGL/egl.h");
  @cInclude("EGL/eglext.h");
});

/// Virtual function table
pub const VTable = struct {
};

pub const Params = struct {
  @"type": base.Type,
  gpu: ?*hardware.device.Gpu,
  vtable: *const VTable,
};

fn egl_init(self: *Self) !void {
  // TODO: move this to DisplayKit renderer type
  std.debug.assert(self.gpu != null);
  const display = self.gpu.?.getEglDisplay();

  if (c.eglInitialize(display, null, null) == c.EGL_FALSE) return error.EglInitialize;
  if (c.eglBindAPI(c.EGL_OPENGL_API) == c.EGL_FALSE) {
    if (c.eglBindAPI(c.EGL_OPENGL_ES_API) == c.EGL_FALSE) return error.EglBind;
  }
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      ._type = params.type,
      .vtable = params.vtable,
      .gpu = if (params.gpu) |gpu| try gpu.ref(t.allocator) else null,
    };

    if (self.gpu != null) {
      // TODO: move this to DisplayKit renderer type
      try egl_init(self);
    }
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      ._type = self._type,
      .vtable = self.vtable,
      .gpu = if (self.gpu) |gpu| try gpu.ref(t.allocator) else null,
    };
  }

  pub fn unref(self: *Self) void {
    if (self.gpu) |gpu| {
      gpu.unref();
    }
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
_type: base.Type,
vtable: *const VTable,
gpu: ?*hardware.device.Gpu,

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

pub fn toCompositor(self: *Self) *Compositor {
  if (self._type != .compositor) @panic("Cannot cast a client to a compositor");
  return Compositor.Type.fromOpaque(self.type.parent.?);
}

pub fn toClient(self: *Self) *Client {
  if (self._type != .client) @panic("Cannot cast a compositor to a client");
  return Client.Type.fromOpaque(self.type.parent.?);
}
