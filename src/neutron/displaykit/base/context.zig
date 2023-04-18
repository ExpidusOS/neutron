const std = @import("std");
const elemental = @import("../../elemental.zig");
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
    };
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

pub fn createRenderSurface(self: *Self, res: @Vector(2, i32), visual: u32) !*anyopaque {
  return self.vtable.create_render_surface(self.type.toOpaque(), res, visual);
}

pub fn resizeRenderSurface(self: *Self, surf: *anyopaque, res: @Vector(2, i32)) !void {
  return self.vtable.resize_render_surface(self.type.toOpaque(), surf, res);
}

pub fn destroyRenderSurface(self: *Self, surf: *anyopaque) void {
  return self.vtable.destroy_render_surface(self.type.toOpaque(), surf);
}
