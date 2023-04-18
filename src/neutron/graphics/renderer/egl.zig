const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const displaykit = @import("../../displaykit.zig");
const Base = @import("base.zig");
const Self = @This();

const c = @cImport({
  @cInclude("EGL/egl.h");
  @cInclude("EGL/eglext.h");
});

const vtable = Base.VTable {
};

pub const Params = struct {
  gpu: *hardware.device.Gpu,
  displaykit: ?*displaykit.base.Context,
  resolution: @Vector(2, i32),
};

fn hasExtension(_clients: [*c]const u8, name: []const u8) bool {
  var clients: []const u8 = undefined;
  clients.ptr = _clients;
  clients.len = std.mem.len(_clients);
  return std.mem.containsAtLeast(u8, clients, 1, name);
}

fn hasDisplayExtension(self: *Self, name: []const u8) bool {
  return hasExtension(c.eglQueryString(self.display, c.EGL_EXTENSIONS), name);
}

fn hasClientExtension(name: []const u8) bool {
  return hasExtension(c.eglQueryString(c.EGL_NO_DISPLAY, c.EGL_EXTENSIONS), name);
}

fn eglWrap(r: c_uint) !void {
  if (r == c.EGL_FALSE) return error.Unknown;
  if (r == c.EGL_BAD_PARAMETER) return error.BadParameter;
}

fn eglWrapBool(r: c_uint) bool {
  eglWrap(r) catch return false;
  return true;
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Base.init(.{
        .vtable = &vtable,
      }, self, t.allocator),
      .gpu = try params.gpu.ref(t.allocator),
      .displaykit = if (params.displaykit) |dk| try dk.ref(t.allocator) else null,
      .display = try self.gpu.getEglDisplay(),
      .context = undefined,
      .surface = undefined,
      .window = null,
    };
    errdefer self.base.unref();

    try eglWrap(c.eglInitialize(self.display, null, null));
    try eglWrap(c.eglBindAPI(c.EGL_OPENGL_ES_API));

    const IMG_context_priority = self.hasDisplayExtension("EGL_IMG_context_priority");

    const attribs = &[_]i32 {
      c.EGL_CONTEXT_CLIENT_VERSION, 2,
      if (IMG_context_priority) c.EGL_CONTEXT_PRIORITY_LEVEL_IMG else c.EGL_NONE,
      if (IMG_context_priority) c.EGL_CONTEXT_PRIORITY_HIGH_IMG else c.EGL_NONE,
      c.EGL_NONE,
    };

    const config = try self.getConfig();
    self.context = try (if (c.eglCreateContext(self.display, config, c.EGL_NO_CONTEXT, attribs)) |value| value else error.InvalidContext);

    try self.updateSurface(params.resolution);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .gpu = try self.gpu.ref(t.allocator),
      .displaykit = if (self.displaykit) |dk| try dk.ref(t.allocator) else null,
      .display = self.display,
      .context = self.context,
      .surface = self.surface,
      .window = self.window,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.gpu.unref();

    if (self.displaykit) |dk| dk.unref();
  }

  pub fn destroy(self: *Self) void {
    _ = c.eglDestroySurface(self.display, self.surface);
    _ = c.eglDestroyContext(self.display, self.context);
    _ = c.eglTerminate(self.display);

    if (self.window) |win| {
      if (self.displaykit) |context| {
        context.destroyRenderSurface(win);
      }
    }
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,
gpu: *hardware.device.Gpu,
displaykit: ?*displaykit.base.Context,
display: c.EGLDisplay,
context: c.EGLContext,
surface: c.EGLSurface,
window: ?*anyopaque,

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

pub fn updateSurface(self: *Self, res: @Vector(2, i32)) !void {
  const config = try self.getConfig();

  var surface_type: c.EGLint = undefined;
  if (c.eglGetConfigAttrib(self.display, config, c.EGL_SURFACE_TYPE, &surface_type) == c.EGL_FALSE) return error.InvalidAttrib;

  var visual: c.EGLint = undefined;
  if (c.eglGetConfigAttrib(self.display, config, c.EGL_NATIVE_VISUAL_ID, &visual) == c.EGL_FALSE) return error.InvalidAttrib;

  if (surface_type == c.EGL_WINDOW_BIT) {
    if (self.displaykit) |context| {
      if (self.window == null) {
        const win = try context.createRenderSurface(res, @intCast(u32, visual));
        self.window = win;
      } else {
        var win = self.window.?;
        context.resizeRenderSurface(win, res) catch {
          context.destroyRenderSurface(win);
          _ = c.eglDestroySurface(self.display, self.surface);
          win = try context.createRenderSurface(res, @intCast(u32, visual));
        };

        self.window = win;
      }

      self.surface = try (if (c.eglCreateWindowSurface(self.display, config, @intCast(c_ulong, @ptrToInt(self.window.?)), null)) |value| value else error.InvalidSurface);
      return;
    }
    return error.RequiresDisplayKit;
  }
  return error.InvalidConfig;
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
