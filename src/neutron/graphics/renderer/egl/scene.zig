const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const Renderer = @import("../../renderer.zig").Renderer;
const EglRenderer = @import("../egl.zig");
const api = @import("../../api/egl.zig");
const Scene = @import("../../scene.zig");
const SceneLayer = @import("../../scene-layer.zig");
const ShaderProgram = @import("shader-program.zig");
const Self = @This();

const c = api.c;

const scene_layer_vtable = SceneLayer.VTable {
  .render = (struct {
    fn callback(_scene_layer: *anyopaque, renderer: *Renderer) !void {
      const scene_layer = SceneLayer.Type.fromOpaque(_scene_layer);

      api.clearError();

      switch (scene_layer.getKind()) {
        .platform => {},
        .backing_store => {
          // FIXME: doesn't output, for whatever reason
          const page_texture = @ptrCast(*EglRenderer.PageTexture, @alignCast(@alignOf(EglRenderer.PageTexture), scene_layer.backing_store.?.user_data));

          var pos_attrib: c.GLint = undefined;
          var texcoord_attrib: c.GLint = undefined;

          c.glActiveTexture(c.GL_TEXTURE0);
          c.glBindTexture(c.GL_TEXTURE_2D, page_texture.tex);

          if (renderer.toBase().shader_prog) |base_shader_prog| {
            const shader_prog = @fieldParentPtr(ShaderProgram, "base", base_shader_prog);

            try shader_prog.base.use();

            pos_attrib = c.glGetAttribLocation(shader_prog.id, "pos");
            if (pos_attrib == -1) return error.InvalidAttrib;

            texcoord_attrib = c.glGetAttribLocation(shader_prog.id, "texcoord");
            if (texcoord_attrib == -1) return error.InvalidAttrib;

            const x1 = 0.0;
            const x2 = 1.0;
            const y1 = 0.0;
            const y2 = 1.0;

            const texcoords = &[_]c.GLfloat {
              x2, y1,
              x1, y1,
              x2, y2,
              x1, y2
            };

            const quad_verts = &[_]c.GLfloat {
              1, 0,
              0, 0,
              1, 1,
              0, 1,
            };

            c.glEnableVertexAttribArray(@intCast(c.GLuint, pos_attrib));
            c.glVertexAttribPointer(@intCast(c.GLuint, pos_attrib), 2, c.GL_FLOAT, c.GL_FALSE, 0, quad_verts);

            c.glEnableVertexAttribArray(@intCast(c.GLuint, texcoord_attrib));
            c.glVertexAttribPointer(@intCast(c.GLuint, texcoord_attrib), 2, c.GL_FLOAT, c.GL_FALSE, 0, texcoords);
          }

          c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);

          if (renderer.toBase().shader_prog) |_| {
            c.glDisableVertexAttribArray(@intCast(c.GLuint, pos_attrib));
            c.glDisableVertexAttribArray(@intCast(c.GLuint, texcoord_attrib));
          }

          c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glUseProgram(0);
        },
      }

      try api.autoError();
    }
  }).callback,
};

const vtable = Scene.VTable {
  .get_layer_vtable = (struct {
    fn callback(base: *anyopaque, layer: *const flutter.c.FlutterLayer) ?*const SceneLayer.VTable {
      _ = base;
      _ = layer;
      return &scene_layer_vtable;
    }
  }).callback,
  .pre_render = (struct {
    fn callback(base: *anyopaque, renderer: *Renderer, size: @Vector(2, i32)) !void {
      _ = base;

      try renderer.egl.pushDebug();
      c.glViewport(0, 0, size[0], size[1]);
      c.glBlendFunc(c.GL_ONE, c.GL_ONE_MINUS_SRC_ALPHA);
      c.glClearColor(0, 0, 0, 1);
      c.glClear(c.GL_COLOR_BUFFER_BIT);
    }
  }).callback,
  .post_render = (struct {
    fn callback(base: *anyopaque, renderer: *Renderer) !void {
      _ = base;

      c.glFlush();
      renderer.egl.popDebug();
    }
  }).callback,
};

pub const Params = struct {};

const Impl = struct {
  pub fn construct(self: *Self, _: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Scene.init(.{
        .vtable = &vtable,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.scene.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.type.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Scene,

pub usingnamespace Type.Impl;