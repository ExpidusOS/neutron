const elemental = @import("../../../elemental.zig");
const flutter_renderer = @import("../../flutter-renderer.zig");
const renderer = @import("renderer.zig");

pub const EGLFlutterRendererValue = struct {};

fn construct(value: *?*anyopaque) void {
  _ = value;
}

fn destroy(value: *?*anyopaque) void {
  _ = value;
}

pub const EGLFlutterRendererTypeName = "NtGraphicsEGLFlutterRenderer";

pub const EGLFlutterRendererType = elemental.ObjectType {
  .name = EGLFlutterRendererTypeName,
  .value = EGLFlutterRendererValue,
  .parent = flutter_renderer.FlutterRendererType(renderer.EGLRendererType),
  .construct = construct,
  .destroy = destroy
};

pub const EGLFlutterRenderer = elemental.Object(EGLFlutterRendererType);
