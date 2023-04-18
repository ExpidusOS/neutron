const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const displaykit = @import("../../displaykit.zig");
const api = @import("../api/egl.zig");
const Renderer = @import("../renderer/egl.zig");
const Base = @import("base.zig");
const Self = @This();

const c = api.c;
usingnamespace api;

const vtable = Base.VTable {
};

pub const Params = struct {
  resolution: @Vector(2, i32),
  renderer: *Renderer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Base.init(.{
        .vtable = &vtable,
        .renderer = &params.renderer.base,
      }, self, t.allocator),
      .surface = undefined,
      .window = null,
    };

    try self.updateSurface(params.resolution);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .surface = self.surface,
      .window = self.window,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }

  pub fn destroy(self: *Self) void {
    const renderer = self.getRenderer();
    _ = c.eglDestroySurface(renderer.display, self.surface);

    if (self.window) |win| {
      if (renderer.displaykit) |context| {
        context.destroyRenderSurface(win);
      }
    }
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,
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
  const renderer = self.getRenderer();
  const config = try renderer.getConfig();

  var surface_type: c.EGLint = undefined;
  if (c.eglGetConfigAttrib(renderer.display, config, c.EGL_SURFACE_TYPE, &surface_type) == c.EGL_FALSE) return error.InvalidAttrib;

  var visual: c.EGLint = undefined;
  if (c.eglGetConfigAttrib(renderer.display, config, c.EGL_NATIVE_VISUAL_ID, &visual) == c.EGL_FALSE) return error.InvalidAttrib;

  if (surface_type == c.EGL_WINDOW_BIT) {
    if (renderer.displaykit) |context| {
      if (self.window == null) {
        const win = try context.createRenderSurface(res, @intCast(u32, visual));
        self.window = win;
      } else {
        var win = self.window.?;
        context.resizeRenderSurface(win, res) catch {
          context.destroyRenderSurface(win);
          _ = c.eglDestroySurface(renderer.display, self.surface);
          win = try context.createRenderSurface(res, @intCast(u32, visual));
        };

        self.window = win;
      }

      self.surface = try (if (c.eglCreateWindowSurface(renderer.display, config, @intCast(c_ulong, @ptrToInt(self.window.?)), null)) |value| value else error.InvalidSurface);
      return;
    }
    return error.RequiresDisplayKit;
  }
  return error.InvalidConfig;
}

pub fn getRenderer(self: *Self) *Renderer {
  return Renderer.Type.fromOpaque(self.type.parent.?);
}
