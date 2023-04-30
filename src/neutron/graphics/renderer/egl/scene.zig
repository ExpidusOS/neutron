const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const Renderer = @import("../../renderer.zig").Renderer;
const EglRenderer = @import("../egl.zig");
const api = @import("../../api/egl.zig");
const gl = @import("../../bindings/gles3v2.zig");
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
          const page_texture = @ptrCast(*EglRenderer.PageTexture, @alignCast(@alignOf(EglRenderer.PageTexture), scene_layer.backing_store.?.user_data));

          var pos_attrib: gl.GLint = undefined;
          var texcoord_attrib: gl.GLint = undefined;

          gl.activeTexture(gl.TEXTURE0);
          gl.bindTexture(gl.TEXTURE_2D, page_texture.tex);

          if (renderer.toBase().shader_prog) |base_shader_prog| {
            const shader_prog = @fieldParentPtr(ShaderProgram, "base", base_shader_prog);

            try shader_prog.base.use();

            pos_attrib = gl.getAttribLocation(shader_prog.id, "pos");
            if (pos_attrib == -1) return error.InvalidAttrib;

            texcoord_attrib = gl.getAttribLocation(shader_prog.id, "texcoord");
            if (texcoord_attrib == -1) return error.InvalidAttrib;

            const tex = gl.getUniformLocation(shader_prog.id, "tex");
            if (tex == -1) return error.InvalidUniform;

            gl.enableVertexAttribArray(@intCast(gl.GLuint, pos_attrib));
            gl.bindBuffer(gl.ARRAY_BUFFER, renderer.egl.quad_vert_buffer);
            gl.vertexAttribPointer(@intCast(gl.GLuint, pos_attrib), 2, gl.FLOAT, gl.FALSE, 0, null);

            gl.enableVertexAttribArray(@intCast(gl.GLuint, texcoord_attrib));
            gl.bindBuffer(gl.ARRAY_BUFFER, renderer.egl.tex_coord_buffer);
            gl.vertexAttribPointer(@intCast(gl.GLuint, texcoord_attrib), 2, gl.FLOAT, gl.FALSE, 0, null);
          }

          gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

          if (renderer.toBase().shader_prog) |_| {
            gl.disableVertexAttribArray(@intCast(gl.GLuint, pos_attrib));
            gl.disableVertexAttribArray(@intCast(gl.GLuint, texcoord_attrib));
            gl.bindBuffer(gl.ARRAY_BUFFER, 0);
          }

          gl.bindTexture(gl.TEXTURE_2D, 0);
          gl.useProgram(0);
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

      gl.viewport(0, 0, size[0], size[1]);
      gl.clearColor(0, 0, 0, 1);
      gl.clear(c.GL_COLOR_BUFFER_BIT);
    }
  }).callback,
  .post_render = (struct {
    fn callback(base: *anyopaque, renderer: *Renderer) !void {
      _ = base;

      gl.flush();
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
