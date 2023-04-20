const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const displaykit = @import("../../displaykit.zig");
const FrameBuffer = @import("../fb.zig");
const api = @import("../api/egl.zig");
const Renderer = @import("../renderer/egl.zig");
const Base = @import("base.zig");
const Self = @This();

const c = api.c;

const vtable = Base.VTable {
  .get_frame_buffer = (struct {
    fn callback(_base: *anyopaque) !*FrameBuffer {
      const base = Base.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      const renderer = self.getRenderer();

      self.mutex.lock();
      defer self.mutex.unlock();

      if (self.window != null and renderer.getDisplayKit() != null) {
        const win = self.window.?;
        const context = renderer.getDisplayKit().?;

        // FIXME: segment faults with 0x0
        const fb = try context.getRenderSurfaceBuffer(win);
        self.fb = fb;
        return fb;
      }
      return error.Invalid;
    }
  }).callback,
  .commit_frame_buffer = (struct {
    fn callback(_base: *anyopaque) !void {
      const base = Base.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      const renderer = self.getRenderer();

      self.mutex.lock();
      defer self.mutex.unlock();

      if (self.window != null and renderer.getDisplayKit() != null and self.fb != null) {
        const win = self.window.?;
        const context = renderer.getDisplayKit().?;

        defer self.fb = null;
        return context.commitRenderSurfaceBuffer(win, self.fb.?);
      }
      return error.Invalid;
    }
  }).callback,
  .resize = (struct {
    fn callback(_base: *anyopaque, res: @Vector(2, i32)) !void {
      const base = Base.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      const renderer = self.getRenderer();
      const config = try renderer.getConfig();

      var surface_type: c.EGLint = undefined;
      if (c.eglGetConfigAttrib(renderer.display, config, c.EGL_SURFACE_TYPE, &surface_type) == c.EGL_FALSE) return error.InvalidAttrib;

      var visual: c.EGLint = undefined;
      if (c.eglGetConfigAttrib(renderer.display, config, c.EGL_NATIVE_VISUAL_ID, &visual) == c.EGL_FALSE) return error.InvalidAttrib;

      self.mutex.lock();
      defer self.mutex.unlock();

      if (surface_type == c.EGL_WINDOW_BIT) {
        if (renderer.getDisplayKit()) |context| {
          if (self.window == null) {
            self.window = try context.createRenderSurface(res, @intCast(u32, visual));
          } else {
            var win = &self.window.?;
            context.resizeRenderSurface(win.*, res) catch {
              context.destroyRenderSurface(win.*);
              _ = c.eglDestroySurface(renderer.display, self.surface);
              win.* = try context.createRenderSurface(res, @intCast(u32, visual));
            };
          }

          self.surface = try (if (c.eglCreateWindowSurface(renderer.display, config, @intCast(c_ulong, @ptrToInt(self.window.?)), null)) |value| value else error.InvalidSurface);
          return;
        }
        return error.RequiresDisplayKit;
      }
      return error.InvalidConfig;
    }
  }).callback,
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
      .fb = null,
      .surface = undefined,
      .window = null,
      .mutex = .{},
    };

    try self.base.resize(params.resolution);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .fb = self.fb,
      .base = try self.base.type.refInit(t.allocator),
      .surface = self.surface,
      .window = self.window,
      .mutex = .{},
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
fb: ?*FrameBuffer,
surface: c.EGLSurface,
window: ?*anyopaque,
mutex: std.Thread.Mutex,

pub usingnamespace Type.Impl;

pub fn getRenderer(self: *Self) *Renderer {
  return Renderer.Type.fromOpaque(self.type.parent.?.getValue());
}
