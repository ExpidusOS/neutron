const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const displaykit = @import("../../displaykit.zig");
const flutter = @import("../../flutter.zig");
const Runtime = @import("../../runtime/runtime.zig");
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
  .get_engine_impl = (struct {
    fn callback(_base: *anyopaque) *flutter.c.FlutterRendererConfig {
      const base = Base.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return &self.flutter;
    }
  }).callback,
  .get_compositor_impl = (struct {
    fn callback(_base: *anyopaque) ?*flutter.c.FlutterCompositor {
      const base = Base.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      self.compositor.user_data = self;
      return &self.compositor;
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
      .flutter_context = undefined,
      .tex_coord_buffer = undefined,
      .quad_vert_buffer = undefined,
      .pages = [_]Page { Page.init(self) } ** 2,
      .curr_page = 0,
      .procs = .{
        .glDrawBuffers = try api.tryResolve(?*const fn (n: c.GLsizei, bufs: [*c]const c.GLenum) callconv(.C) void, "glDrawBuffers"),
      },
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
    self.flutter_context = try (if (c.eglCreateContext(self.display, config, self.context, attribs)) |value| value else error.InvalidContext);

    try self.useContext();

    const x1 = 0.0;
    const x2 = 1.0;
    const y1 = 0.0;
    const y2 = 1.0;

    const texcoords = &[_]c.GLfloat {
      x2, y2,
      x1, y2,
      x2, y1,
      x1, y1
    };

    const quad_verts = &[_]c.GLfloat {
      1, -1,
      -1, -1,
      1, 1,
      -1, 1,
    };

    c.glGenBuffers(1, &self.tex_coord_buffer);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.tex_coord_buffer);
    c.glBufferData(c.GL_ARRAY_BUFFER, texcoords.len, texcoords, c.GL_STATIC_DRAW);

    c.glGenBuffers(1, &self.quad_vert_buffer);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.quad_vert_buffer);
    c.glBufferData(c.GL_ARRAY_BUFFER, quad_verts.len, quad_verts, c.GL_STATIC_DRAW);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    self.unuseContext();
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .gpu = try self.gpu.ref(t.allocator),
      .display = self.display,
      .context = self.context,
      .flutter_context = self.flutter_context,
      .tex_coord_buffer = self.tex_coord_buffer,
      .quad_vert_buffer = self.quad_vert_buffer,
      .pages = self.pages,
      .curr_page = self.curr_page,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.gpu.unref();
  }

  pub fn destroy(self: *Self) void {
    _ = c.eglDestroyContext(self.display, self.flutter_context);
    _ = c.eglDestroyContext(self.display, self.context);
    _ = c.eglTerminate(self.display);
  }
};

const PageTexture = struct {
  size: @Vector(2, usize),
  fbo: c.GLuint,
  tex: c.GLuint,

  pub fn init(renderer: *Self, size: @Vector(2, usize), make_fbo: bool) !PageTexture {
    var fbo: c.GLuint = 0;
    if (make_fbo) {
      c.glGenFramebuffers(1, &fbo);
      c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
    }

    var tex: c.GLuint = 0;
    c.glGenTextures(1, &tex);
    c.glBindTexture(c.GL_TEXTURE_2D, tex);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_BGRA_EXT, @intCast(c_int, size[0]), @intCast(c_int, size[1]), 0, c.GL_BGRA_EXT, c.GL_UNSIGNED_BYTE, null);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    if (make_fbo) {
      c.glFramebufferTexture2D(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, tex, 0);
      
      var bufs = &[_]c.GLenum { c.GL_COLOR_ATTACHMENT0 };
      renderer.procs.glDrawBuffers(1, bufs);

      c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
    }

    c.glBindTexture(c.GL_TEXTURE_2D, 0);

    const err = c.glGetError();
    if (err != 0) return error.glError;

    return .{
      .tex = tex,
      .fbo = fbo,
      .size = size,
    };
  }
};

const Page = struct {
  renderer: *Self,
  textures: std.ArrayList(PageTexture),
  unused_textures: std.ArrayList(PageTexture),

  pub fn init(renderer: *Self) Page {
    return .{
      .renderer = renderer,
      .textures = std.ArrayList(PageTexture).init(renderer.type.allocator),
      .unused_textures = std.ArrayList(PageTexture).init(renderer.type.allocator),
    };
  }

  pub fn getTexture(self: *Page, size: @Vector(2, usize), make_fbo: bool) !*PageTexture {
    for (self.unused_textures.items, 0..) |*page_texture, i| {
      if (page_texture.size[0] == size[0] and page_texture.size[1] == size[1]) {
        const index = self.textures.items.len;
        try self.textures.append(self.unused_textures.swapRemove(i));
        return &self.textures.items[index];
      }
    }

    const index = self.textures.items.len;
    try self.textures.append(try PageTexture.init(self.renderer, size, make_fbo));
    return &self.textures.items[index];
  }
};

pub const Type = elemental.Type(Self, *hardware.device.Gpu, Impl);

@"type": Type,
base: Base,
gpu: *hardware.device.Gpu,
display: c.EGLDisplay,
context: c.EGLContext,
flutter_context: c.EGLContext,
tex_coord_buffer: c.GLuint,
quad_vert_buffer: c.GLuint,
pages: [2]Page,
curr_page: usize,
procs: struct {
  glDrawBuffers: *const fn (n: c.GLsizei, bufs: [*c]const c.GLenum) callconv(.C) void,
},
compositor: flutter.c.FlutterCompositor = .{
  .struct_size = @sizeOf(flutter.c.FlutterCompositor),
  .user_data = null,
  .avoid_backing_store_cache = true,
  .create_backing_store_callback = (struct {
    fn callback(config: [*c]const flutter.c.FlutterBackingStoreConfig, backing_store_out: [*c]flutter.c.FlutterBackingStore, _self: ?*anyopaque) callconv(.C) bool {
      const self = Type.fromOpaque(_self.?);
      const page = &self.pages[self.curr_page];
      const page_texture = page.getTexture(.{ std.math.lossyCast(usize, config.*.size.width), std.math.lossyCast(usize, config.*.size.height) }, false) catch return false;

      backing_store_out.* = .{
        .struct_size = @sizeOf(flutter.c.FlutterBackingStore),
        .user_data = page_texture,
        .type = flutter.c.kFlutterBackingStoreTypeOpenGL,
        .did_update = true,
        .unnamed_0 = .{
          .open_gl = .{
            .type = flutter.c.kFlutterOpenGLTargetTypeTexture,
            .unnamed_0 = .{
              .texture = .{
                .target = c.GL_TEXTURE_2D,
                .name = page_texture.tex,
                .width = page_texture.size[0],
                .height = page_texture.size[1],
                .format = c.GL_BGRA_EXT,
                .user_data = page_texture,
                .destruction_callback = (struct {
                  fn callback(_: ?*anyopaque) callconv(.C) void {}
                }).callback,
              },
            },
          },
        },
      };
      return true;
    }
  }).callback,
  .collect_backing_store_callback = (struct {
    fn callback(backing_store: [*c]const flutter.c.FlutterBackingStore, _self: ?*anyopaque) callconv(.C) bool {
      _ = backing_store;

      const self = Type.fromOpaque(_self.?);
      _ = self;
      return false;
    }
  }).callback,
  .present_layers_callback = (struct {
    fn callback(layers: [*c][*c]const flutter.c.FlutterLayer, layers_count: usize, _self: ?*anyopaque) callconv(.C) bool {
      _ = layers;
      _ = layers_count;

      const self = Type.fromOpaque(_self.?);
      _ = self;
      return false;
    }
  }).callback,
},
flutter: flutter.c.FlutterRendererConfig = .{
  .type = flutter.c.kOpenGL,
  .unnamed_0 = .{
    .open_gl = .{
      .struct_size = @sizeOf(flutter.c.FlutterOpenGLRendererConfig),
      .fbo_reset_after_present = false,
      .fbo_callback = null,
      .surface_transformation = null,
      .gl_external_texture_frame_callback = null,
      .present = null,
      .populate_existing_damage = null,
      .gl_proc_resolver = (struct {
        fn callback(_: ?*anyopaque, name: [*c]const u8) callconv(.C) ?*anyopaque {
          var n: []const u8 = undefined;
          n.ptr = name;
          n.len = std.mem.len(name);

          return api.resolve(?*anyopaque, n);
        }
      }).callback,
      .make_current = (struct {
        fn callback(_runtime: ?*anyopaque) callconv(.C) bool {
          const runtime = Runtime.Type.fromOpaque(_runtime.?);
          const self = @constCast(&runtime.displaykit.toBase()).toContext().renderer.egl;

          self.useContext() catch return false;
          return true;
        }
      }).callback,
      .clear_current = (struct {
        fn callback(_runtime: ?*anyopaque) callconv(.C) bool {
          const runtime = Runtime.Type.fromOpaque(_runtime.?);
          const self = @constCast(&runtime.displaykit.toBase()).toContext().renderer.egl;

          self.unuseContext();
          return true;
        }
      }).callback,
      .make_resource_current = (struct {
        fn callback(_runtime: ?*anyopaque) callconv(.C) bool {
          const runtime = Runtime.Type.fromOpaque(_runtime.?);
          const self = @constCast(&runtime.displaykit.toBase()).toContext().renderer.egl;

          api.wrap(c.eglMakeCurrent(self.display, c.EGL_NO_SURFACE, c.EGL_NO_SURFACE, self.flutter_context)) catch return false;
          return true;
        }
      }).callback,
      .present_with_info = (struct {
        fn callback(_runtime: ?*anyopaque, present: [*c]const flutter.c.FlutterPresentInfo) callconv(.C) bool {
          _ = present;

          const runtime = Runtime.Type.fromOpaque(_runtime.?);
          const self = @constCast(&runtime.displaykit.toBase()).toContext().renderer.egl;
          _ = self;
          return false;
        }
      }).callback,
      .fbo_with_frame_info_callback = (struct {
        fn callback(_runtime: ?*anyopaque, frame: [*c]const flutter.c.FlutterFrameInfo) callconv(.C) u32 {
          _ = frame;

          const runtime = Runtime.Type.fromOpaque(_runtime.?);
          const self = @constCast(&runtime.displaykit.toBase()).toContext().renderer.egl;
          _ = self;
          return 0;
        }
      }).callback,
    },
  },
},

pub usingnamespace Type.Impl;

pub fn hasDisplayExtension(self: *Self, name: []const u8) bool {
  return api.hasExtension(c.eglQueryString(self.display, c.EGL_EXTENSIONS), name);
}

pub fn getConfig(self: *Self) !c.EGLConfig {
  var config_count: c.EGLint = undefined;
  if (c.eglGetConfigs(self.display, null, 0, &config_count) == c.EGL_FALSE or config_count < 1) return error.NoConfigs;

  var configs = try self.type.allocator.alloc(c.EGLConfig, @intCast(usize, config_count));
  defer self.type.allocator.free(configs);

  var attribs = [_]i32 {
    c.EGL_SURFACE_TYPE, c.EGL_PBUFFER_BIT,
    c.EGL_BUFFER_SIZE, 24,
    c.EGL_RED_SIZE, 8,
    c.EGL_GREEN_SIZE, 8,
    c.EGL_BLUE_SIZE, 8,
    c.EGL_ALPHA_SIZE, 0,
    c.EGL_NONE
  };

  var matches: i32 = undefined;
  if (c.eglChooseConfig(self.display, &attribs, configs.ptr, config_count, &matches) == c.EGL_FALSE or matches == 0) {
    attribs[1] = c.EGL_PIXMAP_BIT;
    if (c.eglChooseConfig(self.display, &attribs, configs.ptr, config_count, &matches) == c.EGL_FALSE or matches == 0) {
      attribs[1] = c.EGL_WINDOW_BIT;
      if (c.eglChooseConfig(self.display, &attribs, configs.ptr, config_count, &matches) == c.EGL_FALSE or matches == 0) return error.NoMatches;
    }
  }

  configs.len = @intCast(usize, matches);
  return configs[0];
}

pub fn getDisplayKit(self: *Self) ?*displaykit.base.Context {
  return if (self.type.parent) |*p|
    displaykit.base.Context.Type.fromOpaque(p.getValue())
  else null;
}

pub fn useContext(self: *Self) !void {
  try api.wrap(c.eglMakeCurrent(self.display, c.EGL_NO_SURFACE, c.EGL_NO_SURFACE, self.context));
}

pub fn unuseContext(self: *Self) void {
  api.wrap(c.eglMakeCurrent(self.display, c.EGL_NO_SURFACE, c.EGL_NO_SURFACE, c.EGL_NO_CONTEXT)) catch @panic("Failed to unuse context");
}
