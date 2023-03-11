const elemental = @import("../elemental.zig");
const std = @import("std");

fn impl_is_software(self: *Renderer) bool {
  _ = self;
  return false;
}

fn impl_wait_sync(self: *Renderer) void {
  _ = self;
}

fn impl_render(self: *Renderer) void {
  _ = self;
}

pub const RendererImpl = struct {
  comptime is_software: fn (self: *Renderer) bool = impl_is_software,
  comptime wait_sync: fn (self: *Renderer) void = impl_wait_sync,
  comptime render: fn (self: *Renderer) void = impl_render,
};

pub const RendererValue = struct {
  impl: RendererImpl,
};

fn construct(value: *?*anyopaque) void {
  _ = value;
}

fn destroy(value: *?*anyopaque) void {
  _ = value;
}

pub const RendererTypeName = "NtGraphicsRenderer";

pub const RendererType = elemental.ObjectType {
  .name = RendererTypeName,
  .value = RendererValue,
  .parent = null,
  .construct = construct,
  .destroy = destroy
};

pub const Renderer = elemental.Object(RendererType);
