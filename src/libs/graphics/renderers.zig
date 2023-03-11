const egl = @import("renderers/egl/renderer.zig");
const flutter_egl = @import("renderers/egl/flutter-renderer.zig");

pub const EGLRenderer = egl.EGLRenderer;
pub const EGLFlutterRenderer = flutter_egl.EGLFlutterRenderer;
