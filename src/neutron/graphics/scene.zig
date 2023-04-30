const std = @import("std");
const elemental = @import("../elemental.zig");
const flutter = @import("../flutter.zig");
const Renderer = @import("renderer.zig").Renderer;
const SceneLayer = @import("scene-layer.zig");
const Self = @This();

pub const VTable = struct {
  get_layer_vtable: ?*const fn (self: *anyopaque, layer: *const flutter.c.FlutterLayer) ?*const SceneLayer.VTable = null,
  pre_render: ?*const fn (self: *anyopaque, renderer: *Renderer, size: @Vector(2, i32)) anyerror!void = null,
  post_render: ?*const fn (self: *anyopaque, renderer: *Renderer) anyerror!void = null,
};

pub const Params = struct {
  vtable: ?*const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .layers = try elemental.TypedList(*SceneLayer).new(.{}, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .layers = self.layers,
    };
  }

  pub fn destroy(self: *Self) void {
    self.layers.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: ?*const VTable,
layers: *elemental.TypedList(*SceneLayer),

pub usingnamespace Type.Impl;

pub fn clearLayers(self: *Self) void {
  while (self.layers.pop()) |_| {}
}

pub fn addLayer(self: *Self, layer: *const flutter.c.FlutterLayer) !void {
  const vtable = if (self.vtable) |vtable|
    if (vtable.get_layer_vtable) |get_layer_vtable| get_layer_vtable(self.type.toOpaque(), layer) else null
  else null;

  try self.layers.append(try SceneLayer.new(.{
    .value = layer,
    .vtable = vtable,
  }, self, self.type.allocator));
}

pub fn render(self: *Self, renderer: *Renderer, size: @Vector(2, i32)) !void {
  if (self.vtable) |vtable| {
    if (vtable.pre_render) |pre_render| {
      try pre_render(self.type.toOpaque(), renderer, size);
    }
  }

  for (self.layers.items) |layer| {
    try layer.render(renderer);
  }

  if (self.vtable) |vtable| {
    if (vtable.post_render) |post_render| {
      try post_render(self.type.toOpaque(), renderer);
    }
  }
}
