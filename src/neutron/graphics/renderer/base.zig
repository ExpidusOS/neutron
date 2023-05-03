const std = @import("std");
const elemental = @import("../../elemental.zig");
const flutter = @import("../../flutter.zig");
const hardware = @import("../../hardware.zig");
const displaykit = @import("../../displaykit.zig");
const subrenderer = @import("../subrenderer.zig");
const Scene = @import("../scene.zig");
const ShaderProgram = @import("../shader-program.zig");
const Self = @This();

pub const VTable = struct {
  create_subrenderer: *const fn (self: *anyopaque, res: @Vector(2, i32)) anyerror!subrenderer.Subrenderer,
  get_engine_impl: *const fn (self: *anyopaque) *flutter.c.FlutterRendererConfig,
  get_compositor_impl: ?*const fn (self: *anyopaque) ?*flutter.c.FlutterCompositor = null,
  create_shader_program: ?*const fn (self: *anyopaque) anyerror!*ShaderProgram = null,
};

pub const Params = struct {
  vtable: *const VTable,
  current_scene: *Scene,
  common: CommonParams,
};

pub const CommonParams = struct {
  gpu: ?*hardware.device.Gpu,
  displaykit: ?*displaykit.base.Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .current_scene = try params.current_scene.ref(t.allocator),
      .shader_prog = null,
      .gpu = params.common.gpu,
      .displaykit = params.common.displaykit,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .current_scene = try self.current_scene.ref(t.allocator),
      .shader_prog = if (self.shader_prog) |shader_prog| try shader_prog.ref(t.allocator) else null,
      .gpu = self.gpu,
      .displaykit = self.displaykit,
    };
  }

  pub fn unref(self: *Self) void {
    self.current_scene.unref();

    if (self.shader_prog) |shader_prog| {
      shader_prog.unref();
      self.shader_prog = null;
    }
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
current_scene: *Scene,
vtable: *const VTable,
shader_prog: ?*ShaderProgram,
gpu: ?*hardware.device.Gpu,
displaykit: ?*displaykit.base.Context,

pub usingnamespace Type.Impl;

pub fn createSubrenderer(self: *Self, res: @Vector(2, i32)) !subrenderer.Subrenderer {
  return self.vtable.create_subrenderer(self.type.toOpaque(), res);
}

pub fn getEngineImpl(self: *Self) *flutter.c.FlutterRendererConfig {
  return self.vtable.get_engine_impl(self.type.toOpaque());
}

pub fn getCompositorImpl(self: *Self) ?*flutter.c.FlutterCompositor {
  if (self.vtable.get_compositor_impl) |get_compositor_impl| {
    return get_compositor_impl(self.type.toOpaque());
  }
  return null;
}

pub fn createShaderProgram(self: *Self) !*ShaderProgram {
  if (self.vtable.create_shader_program) |create_shader_program| {
    return create_shader_program(self.type.toOpaque());
  }
  return error.NotImplemented;
}

pub fn useDefaultShaders(self: *Self) !void {
  if (self.shader_prog) |shader_prog| {
    shader_prog.unref();
    self.shader_prog = null;
  }

  const shader_prog = try self.createShaderProgram();
  try shader_prog.attach(.fragment, @embedFile("../shaders/frag.glsl"));
  try shader_prog.attach(.vertex, @embedFile("../shaders/vert.glsl"));
  try shader_prog.link();

  self.shader_prog = shader_prog;
}
