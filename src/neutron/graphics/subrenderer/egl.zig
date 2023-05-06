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

  pub fn use(self: FbRenderable, _: *Self) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  }

  pub fn unuse(self: FbRenderable, subrenderer: *Self) void {
    _ = self;
    const renderer = subrenderer.getRenderer();

    renderer.procs.glDrawBuffers(1, &[_]c.GLenum { c.GL_COLOR_ATTACHMENT0 });
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
  }

  pub fn destroy(self: FbRenderable, subrenderer: *Self) void {
    const renderer = subrenderer.getRenderer();
    const eglDestroyImageKHR = api.tryResolve(c.PFNEGLDESTROYIMAGEKHRPROC, "eglDestroyImageKHR") catch @panic("Not implemented");

    _ = eglDestroyImageKHR(renderer.display, self.image_khr);
    c.glDeleteFramebuffers(1, &self.fbo);
    c.glDeleteRenderbuffers(1, &self.rbo);
  }
};

const TextureFbRenderable = struct {
  tex: c.GLuint,
  fbo: c.GLuint,

  pub fn use(self: TextureFbRenderable, subrenderer: *Self) !void {
    const res = subrenderer.fb.?.getResolution();

    c.glBindTexture(c.GL_TEXTURE_2D, self.tex);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, @intCast(c_int, res[0]), @intCast(c_int, res[1]), 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  }

  pub fn unuse(self: TextureFbRenderable, subrenderer: *Self) !void {
    _ = self;

    const renderer = subrenderer.getRenderer();
    const res = subrenderer.fb.?.getResolution();
    const stride = @intCast(i32, subrenderer.fb.?.getStride());
    const size = res[1] * stride;

    renderer.procs.glDrawBuffers(1, &[_]c.GLenum { c.GL_COLOR_ATTACHMENT0 });
    c.glReadBuffer(c.GL_COLOR_ATTACHMENT0);
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
    c.glBindTexture(c.GL_TEXTURE_2D, 0);
    
    const buffer = try subrenderer.fb.?.getBuffer();
    @memset(buffer, 0, size);
    _ = try subrenderer.fb.?.commit();
  }

  pub fn destroy(self: TextureFbRenderable, subrenderer: *Self) void {
    _ = subrenderer;

    c.glDeleteFramebuffers(1, &self.fbo);
  }
};

const Renderable = union(enum) {
  fb: FbRenderable,
  tfb: TextureFbRenderable,

  pub fn use(self: Renderable, subrenderer: *Self) !void {
    return switch (self) {
      .fb => |fb| fb.use(subrenderer),
      .tfb => |tfb| tfb.use(subrenderer),
    };
  }

  pub fn unuse(self: Renderable, subrenderer: *Self) !void {
    return switch (self) {
      .fb => |fb| fb.unuse(subrenderer),
      .tfb => |tfb| tfb.unuse(subrenderer),
    };
  }

  pub fn destroy(self: Renderable, subrenderer: *Self) void {
    return switch (self) {
      .fb => |fb| fb.destroy(subrenderer),
      .tfb => |tfb| tfb.destroy(subrenderer),
    };
  }
};

pub const Params = struct {
  renderer: *Renderer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = undefined,
      .fb = null,
      .renderable = null,
      .mutex = .{},
    };

    _ = try Base.init(&self.base, .{
      .vtable = &self.vtable,
      .renderer = &params.renderer.base,
    }, self, t.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = undefined,
      .fb = if (self.fb) |fb| try fb.ref(t.allocator) else null,
      .renderable = self.renderable,
      .mutex = .{},
    };

    _ = try self.base.type.refInit(&dest.base, t.allocator);
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

fn updateFrameBufferEglImage(self: *Self, fb: *FrameBuffer) !bool {
  const renderer = self.getRenderer();
  const eglCreateImageKHR = try api.tryResolve(c.PFNEGLCREATEIMAGEKHRPROC, "eglCreateImageKHR");
  const glEGLImageTargetRenderbufferStorageOES = try api.tryResolve(c.PFNGLEGLIMAGETARGETRENDERBUFFERSTORAGEOESPROC, "glEGLImageTargetRenderbufferStorageOES");
  const is_set = self.fb != null;

  if (is_set) {
    self.renderable.?.destroy(self);
    self.fb.?.unref();

    self.renderable = null;
    self.fb = null;
  }

  if (renderer.base.displaykit) |ctx| {
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
    return true;
  }
  return error.MissingDisplayKit;
}

@"type": Type,
base: Base,
fb: ?*FrameBuffer,
mutex: std.Thread.Mutex,
renderable: ?Renderable,
vtable: Base.VTable = .{
  .update_frame_buffer = (struct {
    fn callback(_base: *anyopaque, fb: *FrameBuffer) !void {
      const base = Base.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);
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

      var updated: bool = false;

      if (surface_type == c.EGL_WINDOW_BIT) {
        if (renderer.hasDisplayExtension("EGL_KHR_image_base")) {

          if (outdated) {
            updated = updateFrameBufferEglImage(self, fb) catch false;
          }
        }
      }

      if (!updated) {
        if (self.fb) |_fb| {
          _fb.unref();
          self.fb = null;
        }

        if (self.renderable) |rb| {
          rb.destroy(self);
          self.renderable = null;
        }

        const res = fb.getResolution();

        api.clearError();

        var renderable = TextureFbRenderable {
          .tex = undefined,
          .fbo = undefined,
        };

        c.glGenTextures(1, &renderable.tex);
        c.glBindTexture(c.GL_TEXTURE_2D, renderable.tex);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, @intCast(c_int, res[0]), @intCast(c_int, res[1]), 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
        c.glBindTexture(c.GL_TEXTURE_2D, 0);

        c.glGenFramebuffers(1, &renderable.fbo);
        c.glBindFramebuffer(c.GL_FRAMEBUFFER, renderable.fbo);
        c.glFramebufferTexture2D(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, renderable.tex, 0);

        var status = c.glCheckFramebufferStatus(c.GL_FRAMEBUFFER);
        c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

        if (status != c.GL_FRAMEBUFFER_COMPLETE) return api.autoError();

        self.renderable = .{
          .tfb = renderable
        };

        self.fb = try fb.ref(self.type.allocator);
      }

      std.debug.assert(self.renderable != null and self.fb != null);
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
        try renderable.use(self);
      }

      renderer.mutex.lock();
      defer renderer.mutex.unlock();

      if (self.fb) |fb| {
        try renderer.base.current_scene.render(&.{
          .egl = renderer,
        }, fb.getResolution());
      }

      if (self.renderable) |renderable| {
        try renderable.unuse(self);
      }
    }
  }).callback,
},

pub usingnamespace Type.Impl;

pub fn getRenderer(self: *Self) *Renderer {
  return Renderer.Type.fromOpaque(self.base.renderer.type.parent.?.getValue());
}
