const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const displaykit = @import("../../displaykit.zig");
const api = @import("../api/egl.zig");
const subrenderer = @import("../subrenderer.zig");
const Base = @import("base.zig");
const Self = @This();

const c = api.c;

const vtable = Base.VTable {
  .create_subrenderer = (struct {
    fn callback(_base: *anyopaque, res: @Vector(2, i32)) !subrenderer.Subrenderer {
      const base = Base.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return .{
        .egl = try subrenderer.Egl.new(.{
          .renderer = self,
          .resolution = res,
        }, self, null),
      };
    }
  }).callback,
};

const Impl = struct {
  pub fn construct(self: *Self, gpu: *hardware.device.Gpu, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Base.init(.{
        .vtable = &vtable,
      }, self, t.allocator),
      .gpu = try gpu.ref(t.allocator),
      .display = try self.gpu.getEglDisplay(),
      .context = undefined,
    };
    errdefer self.base.unref();

    try api.wrap(c.eglInitialize(self.display, null, null));
    try api.wrap(c.eglBindAPI(c.EGL_OPENGL_ES_API));

    const IMG_context_priority = self.hasDisplayExtension("EGL_IMG_context_priority");

    const attribs = &[_]i32 {
      c.EGL_CONTEXT_CLIENT_VERSION, 2,
      if (IMG_context_priority) c.EGL_CONTEXT_PRIORITY_LEVEL_IMG else c.EGL_NONE,
      if (IMG_context_priority) c.EGL_CONTEXT_PRIORITY_HIGH_IMG else c.EGL_NONE,
      c.EGL_NONE,
    };

    const config = try self.getConfig();
    self.context = try (if (c.eglCreateContext(self.display, config, c.EGL_NO_CONTEXT, attribs)) |value| value else error.InvalidContext);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .gpu = try self.gpu.ref(t.allocator),
      .display = self.display,
      .context = self.context,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.gpu.unref();
  }

  pub fn destroy(self: *Self) void {
    _ = c.eglDestroyContext(self.display, self.context);
    _ = c.eglTerminate(self.display);
  }
};

pub const Type = elemental.Type(Self, *hardware.device.Gpu, Impl);

@"type": Type,
base: Base,
gpu: *hardware.device.Gpu,
display: c.EGLDisplay,
context: c.EGLContext,

pub usingnamespace Type.Impl;

pub fn hasDisplayExtension(self: *Self, name: []const u8) bool {
  return api.hasExtension(c.eglQueryString(self.display, c.EGL_EXTENSIONS), name);
}

pub fn getConfig(self: *Self) !c.EGLConfig {
  var config_count: c.EGLint = undefined;
  if (c.eglGetConfigs(self.display, null, 0, &config_count) == c.EGL_FALSE or config_count < 1) return error.NoConfigs;

  var configs = try self.type.allocator.alloc(c.EGLConfig, @intCast(usize, config_count));
  defer self.type.allocator.free(configs);

  const attribs = &[_]i32 {
    c.EGL_SURFACE_TYPE, c.EGL_WINDOW_BIT,
    c.EGL_BUFFER_SIZE, 24,
    c.EGL_RED_SIZE, 8,
    c.EGL_GREEN_SIZE, 8,
    c.EGL_BLUE_SIZE, 8,
    c.EGL_ALPHA_SIZE, 0,
    c.EGL_NONE
  };

  var matches: i32 = undefined;
  if (c.eglChooseConfig(self.display, attribs, configs.ptr, config_count, &matches) == c.EGL_FALSE or matches == 0) return error.NoMatches;

  configs.len = @intCast(usize, matches);
  return configs[0];
}

pub fn getDisplayKit(self: *Self) ?*displaykit.base.Context {
  return if (self.type.parent) |*p|
    displaykit.base.Context.Type.fromOpaque(p.getValue())
  else null;
}
