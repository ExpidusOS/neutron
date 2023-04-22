const std = @import("std");

pub const c = @cImport({
  @cInclude("GL/gl.h");
  @cInclude("GL/glext.h");
  @cInclude("GLES2/gl2.h");
  @cInclude("GLES2/gl2ext.h");
  @cInclude("EGL/egl.h");
  @cInclude("EGL/eglext.h");
});

pub fn hasExtension(_clients: [*c]const u8, name: []const u8) bool {
  var clients: []const u8 = undefined;
  clients.ptr = _clients;
  clients.len = std.mem.len(_clients);
  return std.mem.containsAtLeast(u8, clients, 1, name);
}

pub fn hasClientExtension(name: []const u8) bool {
  return hasExtension(c.eglQueryString(c.EGL_NO_DISPLAY, c.EGL_EXTENSIONS), name);
}

pub fn wrap(r: c_uint) !void {
  if (r == c.EGL_FALSE) return error.Unknown;
  if (r == c.EGL_BAD_PARAMETER) return error.BadParameter;
}

pub fn wrapBool(r: c_uint) bool {
  wrap(r) catch return false;
  return true;
}

pub fn resolve(comptime T: type, name: []const u8) ?@typeInfo(T).Optional.child {
  return if (c.eglGetProcAddress(name.ptr)) |proc|
    @ptrCast(T, @constCast(proc))
  else null;
}

pub fn tryResolve(comptime T: type, name: []const u8) !@typeInfo(T).Optional.child {
  return resolve(T, name) orelse error.NoProc;
}
