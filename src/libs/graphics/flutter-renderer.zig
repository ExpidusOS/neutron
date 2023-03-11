const elemental = @import("../elemental.zig");
const renderer = @import("renderer.zig");
const std = @import("std");

const Renderer = renderer.Renderer;

const c = @cImport({
  @cInclude("flutter_embedder.h");
});

fn impl_get_config(self: *FlutterRenderer) ?*c.FlutterRendererConfig {
  _ = self;
  return null;
}

fn impl_get_compositor(self: *FlutterRenderer) ?c.FlutterCompositor {
  _ = self;
  return null;
}

pub const FlutterRendererImpl = struct {
  comptime get_config: fn (self: *FlutterRenderer) ?*c.FlutterRendererConfig = impl_get_config,
  comptime get_compositor: fn (self: *FlutterRenderer) ?c.FlutterCompositor = impl_get_compositor,
};

pub const FlutterRendererValue = struct {
  flutter_impl: FlutterRendererImpl
};

fn construct(value: *?*anyopaque) void {
  const self = @fieldParentPtr(FlutterRenderer, "value", @ptrCast(*?*FlutterRendererValue, value));
  _ = self;
}

fn destroy(value: *?*anyopaque) void {
  const self = @fieldParentPtr(FlutterRenderer, "value", @ptrCast(*?*FlutterRendererValue, value));
  _ = self;
}

pub const FlutterRendererTypeName = "NtGraphicsFlutterRenderer";

pub fn FlutterRendererType(comptime type_info: elemental.ObjectType) elemental.ObjectType {
  if (type_info.parent != Renderer) @compileError("type_info.parent must be Renderer");

  return .{
    .name = FlutterRendererTypeName,
    .value = FlutterRendererValue,
    .parent = type_info,
    .construct = construct,
    .destroy = destroy,
  };
}

pub const FlutterRenderer = elemental.Object(FlutterRendererType(Renderer));
