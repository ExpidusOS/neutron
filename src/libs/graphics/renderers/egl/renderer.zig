const elemental = @import("../../../elemental.zig");
const renderer = @import("../../renderer.zig");

pub const EGLRendererValue = struct {};

fn construct(value: *?*anyopaque) void {
  _ = value;
}

fn destroy(value: *?*anyopaque) void {
  _ = value;
}

pub const EGLRendererTypeName = "NtGraphicsEGLRenderer";

pub const EGLRendererType = elemental.ObjectType {
  .name = EGLRendererTypeName,
  .value = EGLRendererValue,
  .parent = &renderer.RendererType,
  .construct = construct,
  .destroy = destroy,
};

pub const EGLRenderer = elemental.Object(EGLRendererType);
