const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const hardware = @import("../../hardware.zig");
const Compositor = @import("compositor.zig");
const Client = @import("client.zig");
const base = @import("base.zig");
const Output = @import("output.zig");
const input = @import("input.zig");
const Self = @This();

pub const EGLImageKHRParameters = struct {
  target: c_uint,
  buffer: ?*anyopaque,
  attribs: []i32,
};

/// Virtual function table
pub const VTable = struct {
  get_egl_image_khr_parameters: ?*const fn (self: *anyopaque, fb: *graphics.FrameBuffer) anyerror!EGLImageKHRParameters = null,
  get_outputs: ?*const fn (self: *anyopaque) anyerror!*elemental.TypedList(*Output) = null,
  get_inputs: ?*const fn (self: *anyopaque) anyerror!*elemental.TypedList(input.Input) = null,
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
      .renderer = try graphics.renderer.Renderer.init(params.renderer, .{
        .gpu = self.gpu,
        .displaykit = self,
      }, t.allocator),
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
  return Compositor.Type.fromOpaque(self.type.parent.?.getValue());
}

pub fn toClient(self: *Self) *Client {
  if (self._type != .client) @panic("Cannot cast a compositor to a client");
  return Client.Type.fromOpaque(self.type.parent.?.getValue());
}

pub fn getEGLImageKHRParameters(self: *Self, fb: *graphics.FrameBuffer) !EGLImageKHRParameters {
  if (self.vtable.get_egl_image_khr_parameters) |get_egl_image_khr_parameters| {
    return get_egl_image_khr_parameters(self.type.toOpaque(), fb);
  }
  return error.NotImplemented;
}

pub fn getOutputs(self: *Self) !*elemental.TypedList(*Output) {
  if (self.vtable.get_outputs) |get_outputs| {
    return get_outputs(self.type.toOpaque());
  }

  return elemental.TypedList(*Output).new(.{}, null, self.type.allocator);
}

pub fn getInputs(self: *Self) !*elemental.TypedList(input.Input) {
  if (self.vtable.get_inputs) |get_inputs| {
    return get_inputs(self.type.toOpaque());
  }

  return elemental.TypedList(input.Input).new(.{}, null, self.type.allocator);
}

pub fn getInputsByKind(self: *Self, comptime kind: input.Type) !*elemental.TypedList(std.meta.fieldInfo(input.Input, kind).type) {
  var inputs = try self.getInputs();
  defer inputs.unref();

  var list = try elemental.TypedList(std.meta.fieldInfo(input.Input, kind).type).new(.{}, null, self.type.allocator);
  errdefer list.unref();

  for (inputs.items) |item| {
    if (item == kind) {
      const value = @field(item, @tagName(kind));
      try list.append(value);
    }
  }
  return list;
}
