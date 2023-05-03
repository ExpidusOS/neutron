const std = @import("std");
const elemental = @import("../../../elemental.zig");
const api = @import("../../api/egl.zig");
const BaseShader = @import("../../shader.zig");
const ShaderProgram = @import("../../shader-program.zig");
const Shader = @import("shader.zig");
const Self = @This();

const c = api.c;

const vtable = ShaderProgram.VTable {
  .attach = (struct {
    fn callback(_base: *anyopaque, base_shader: *BaseShader) !void {
      const base = ShaderProgram.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);
      const shader = @fieldParentPtr(Shader, "base", base_shader);

      api.clearError();
      c.glAttachShader(self.id, shader.id);
      try api.autoError();
    }
  }).callback,
  .detach = (struct {
    fn callback(_base: *anyopaque, base_shader: *BaseShader) !void {
      const base = ShaderProgram.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);
      const shader = @fieldParentPtr(Shader, "base", base_shader);

      api.clearError();
      c.glDetachShader(self.id, shader.id);
      try api.autoError();
    }
  }).callback,
  .link = (struct {
    fn callback(_base: *anyopaque) !void {
      const base = ShaderProgram.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);

      api.clearError();
      c.glLinkProgram(self.id);
      try api.autoError();
    }
  }).callback,
  .use = (struct {
    fn callback(_base: *anyopaque) !void {
      const base = ShaderProgram.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);

      api.clearError();
      c.glUseProgram(self.id);
      try api.autoError();
    }
  }).callback,
  .create_shader = (struct {
    fn callback(_base: *anyopaque, kind: BaseShader.Kind, code: []const u8) !*BaseShader {
      const base = ShaderProgram.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);

      return &(try Shader.new(.{
        .kind = kind,
        .code = code,
      }, null, self.type.allocator)).base;
    }
  }).callback,
};

pub const Params = struct {};

const Impl = struct {
  pub fn construct(self: *Self, _: Params, t: Type) !void {
    api.clearError();

    const id = c.glCreateProgram();
    if (id == 0) return error.ShaderError;
    errdefer c.glDeleteProgram(id);

    self.* = .{
      .type = t,
      .id = id,
      .base = try ShaderProgram.init(&self.base, .{
        .vtable = &vtable,
      }, self, t.allocator),
    };

    try api.autoError();
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .id = self.id,
      .base = try self.base.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }

  pub fn destroy(self: *Self) void {
    c.glDeleteProgram(self.id);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: ShaderProgram,
id: c.GLuint,

pub usingnamespace Type.Impl;
