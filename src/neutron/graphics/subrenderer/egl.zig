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

const FbRenderable = struct {
  image_khr: c.EGLImageKHR,
  rbo: c.GLuint,
  fbo: c.GLuint,

  pub fn use(self: FbRenderable) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  }

  pub fn unuse(self: FbRenderable) void {
    _ = self;

    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
  }
};

const Renderable = union(enum) {
  fb: FbRenderable,

  pub fn use(self: Renderable) void {
    return switch (self) {
      .fb => |fb| fb.use(),
    };
  }

  pub fn unuse(self: Renderable) void {
    return switch (self) {
      .fb => |fb| fb.unuse(),
    };
  }
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
        .vtable = &self.vtable,
        .renderer = &params.renderer.base,
      }, self, t.allocator),
      .fb = null,
      .renderable = null,
      .mutex = .{},
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .fb = if (self.fb) |fb| try fb.ref(t.allocator) else null,
      .renderable = self.renderable,
      .mutex = .{},
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();

    if (self.fb) |fb| {
      fb.unref();
      self.fb = null;
    }
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,
fb: ?*FrameBuffer,
mutex: std.Thread.Mutex,
renderable: ?Renderable,
vtable: Base.VTable = .{
  .update_frame_buffer = (struct {
    fn callback(_base: *anyopaque, fb: *FrameBuffer) !void {
      const base = Base.Type.fromOpaque(_base);
      const self = @constCast(@fieldParentPtr(Self, "vtable", base.vtable));
      const renderer = self.getRenderer();

      self.mutex.lock();
      defer self.mutex.unlock();

      const is_set = self.fb != null;
      const outdated = self.fb != fb;

      const surface_type: c.EGLint = (blk: {
        const config = try renderer.getConfig();
        var value: c.EGLint = undefined;
        if (c.eglGetConfigAttrib(renderer.display, config, c.EGL_SURFACE_TYPE, &value) == c.EGL_FALSE) break :blk error.ConfigAttrib;
        break :blk value;
      }) catch c.EGL_WINDOW_BIT;

      std.debug.assert(if (is_set) self.renderable != null else self.renderable == null);

      if (surface_type == c.EGL_WINDOW_BIT) {
        if (renderer.hasDisplayExtension("EGL_KHR_image_base")) {
          const eglCreateImageKHR = try api.tryResolve(c.PFNEGLCREATEIMAGEKHRPROC, "eglCreateImageKHR");
          const eglDestroyImageKHR = try api.tryResolve(c.PFNEGLDESTROYIMAGEKHRPROC, "eglDestroyImageKHR");
          const glEGLImageTargetRenderbufferStorageOES = try api.tryResolve(c.PFNGLEGLIMAGETARGETRENDERBUFFERSTORAGEOESPROC, "glEGLImageTargetRenderbufferStorageOES");

          if (outdated) {
            if (is_set) {
              _ = eglDestroyImageKHR(renderer.display, self.renderable.?.fb.image_khr);
              self.fb.?.unref();

              self.renderable = null;
              self.fb = null;
            }

            if (renderer.getDisplayKit()) |ctx| {
              const params = try ctx.getEGLImageKHRParameters(fb);

              const image_khr = try (if (eglCreateImageKHR(renderer.display, c.EGL_NO_CONTEXT, params.target, params.buffer, (&params.attribs).ptr)) |value| value else error.InvalidKHR);

              try renderer.useContext();
              defer renderer.unuseContext();

              var renderable = FbRenderable {
                .image_khr = image_khr,
                .rbo = undefined,
                .fbo = undefined,
              };

              c.glGenRenderbuffers(1, &renderable.rbo);
              c.glBindRenderbuffer(c.GL_RENDERBUFFER, renderable.rbo);
              glEGLImageTargetRenderbufferStorageOES(c.GL_RENDERBUFFER, image_khr);
              c.glBindRenderbuffer(c.GL_RENDERBUFFER, 0);

              c.glGenFramebuffers(1, &renderable.fbo);
              c.glBindFramebuffer(c.GL_FRAMEBUFFER, renderable.fbo);
              c.glFramebufferRenderbuffer(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_RENDERBUFFER, renderable.rbo);

              var status = c.glCheckFramebufferStatus(c.GL_FRAMEBUFFER);
              c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

              if (status != c.GL_FRAMEBUFFER_COMPLETE) return error.FrameBuffer;

              self.renderable = .{
                .fb = renderable
              };

              self.fb = try fb.ref(self.type.allocator);
            } else {
              return error.MissingDisplayKit;
            }
          }
          return;
        }
        return error.MissingExtension;
      }
    }
  }).callback,
  .render = (struct {
    fn callback(_base: *anyopaque) !void {
      const base = Base.Type.fromOpaque(_base);
      const self = @constCast(@fieldParentPtr(Self, "vtable", base.vtable));
      const renderer = self.getRenderer();

      self.mutex.lock();
      defer self.mutex.unlock();

      try renderer.useContext();
      defer renderer.unuseContext();

      if (self.renderable) |renderable| {
        renderable.use();
      }

      c.glClearColor(1, 0, 0, 1);
      c.glClear(c.GL_COLOR_BUFFER_BIT);
      c.glFlush();

      if (self.renderable) |renderable| {
        renderable.unuse();
      }
    }
  }).callback,
},

pub usingnamespace Type.Impl;

pub fn getRenderer(self: *Self) *Renderer {
  return Renderer.Type.fromOpaque(self.type.parent.?.getValue());
}
