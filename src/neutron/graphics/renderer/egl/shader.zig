const std = @import("std");
const elemental = @import("../../../elemental.zig");
const api = @import("../../api/egl.zig");
const Shader = @import("../../shader.zig");
const Self = @This();

const c = api.c;

const vtable = Shader.VTable {
  .set_code = (struct {
    fn callback(_base: *anyopaque, code: []const u8) !void {
      const base = Shader.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "base", base);

      api.clearError();

      c.glShaderSource(self.id, 1, @ptrCast([*c][*c]const u8, @constCast(&code)), null);
      c.glCompileShader(self.id);

      var ok: c.GLint = c.GL_FALSE;
      c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, &ok);
      if (ok == c.GL_FALSE) {
        var log_len: c.GLint = 0;
        c.glGetShaderiv(self.id, c.GL_INFO_LOG_LENGTH, &log_len);

        var log = try self.type.allocator.alloc(u8, @intCast(usize, log_len));
        defer self.type.allocator.free(log);
        c.glGetShaderInfoLog(self.id, log_len, @ptrCast(*c.GLsizei, @constCast(&log.len)), log.ptr);

        std.debug.print("Failed to compile {} shader: {s}\nCode:\n{s}\n", .{ self.base.kind, log, code });
        return error.CompileFail;
      }

      try api.autoError();
    }
  }).callback,
};

pub const Params = struct {
  kind: Shader.Kind,
  code: ?[]const u8,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    api.clearError();

    var id = c.glCreateShader(switch (params.kind) {
      .vertex => c.GL_VERTEX_SHADER,
      .fragment => c.GL_FRAGMENT_SHADER,
    });

    if (id == 0) return error.ShaderError;
    errdefer {
      c.glDeleteShader(id);
      id = 0;
      self.id = id;
    }

    self.* = .{
      .type = t,
      .id = id,
      .base = try Shader.init(&self.base, .{
        .vtable = &vtable,
        .kind = params.kind,
      }, self, t.allocator),
    };

    if (params.code) |code| {
      try self.base.setCode(code);
    }

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
    c.glDeleteShader(self.shader);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Shader,
id: c.GLuint,

pub usingnamespace Type.Impl;
