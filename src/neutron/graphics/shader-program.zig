const std = @import("std");
const elemental = @import("../elemental.zig");
const Shader = @import("shader.zig");
const Self = @This();

pub const Entry = struct {
  kind: Shader.Kind,
  code: []const u8,

  pub fn format(self: Entry, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    return writer.print("{}:\n{s}\n", .{ self.kind, self.code });
  }
};

pub const VTable = struct {
  create_shader: *const fn (self: *anyopaque, kind: Shader.Kind, code: []const u8) anyerror!*Shader,
  attach: *const fn (self: *anyopaque, shader: *Shader) anyerror!void,
  detach: *const fn (self: *anyopaque, shader: *Shader) anyerror!void,
  link: *const fn (self: *anyopaque) anyerror!void,
  use: *const fn (self: *anyopaque) anyerror!void,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .shaders = try elemental.TypedList(*Shader).new(.{}, null, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .shaders = try self.shaders.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.shaders.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
shaders: *elemental.TypedList(*Shader),

pub usingnamespace Type.Impl;

pub fn createShader(self: *Self, kind: Shader.Kind, code: []const u8) !*Shader {
  return self.vtable.create_shader(self.type.toOpaque(), kind, code);
}

pub fn attach(self: *Self, kind: Shader.Kind, code: []const u8) !void {
  const shader = try self.createShader(kind, code);
  return try self.attachShader(shader);
}

pub fn attachShader(self: *Self, shader: *Shader) !void {
  try self.vtable.attach(self.type.toOpaque(), shader);
  try self.shaders.appendOwned(shader);
}

pub fn detachShader(self: *Self, i: usize) !void {
  if (self.shaders.remove(i)) |shader| {
    try self.vtable.detach(self.type.toOpaque(), shader);
  }

  return error.ShaderNotFound;
}

pub fn link(self: *Self) !void {
  return self.vtable.link(self.type.toOpaque());
}

pub fn linkWith(self: *Self, shaders: []*Shader) !void {
  for (shaders) |shader| {
    try self.attachShader(shader);
  }

  return self.link();
}

pub fn use(self: *Self) !void {
  return self.vtable.use(self.type.toOpaque());
}
