const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Gpu = @import("../../base/device/gpu.zig");
const c = @cImport({
  @cInclude("EGL/egl.h");
  @cInclude("EGL/eglext.h");
  @cInclude("xf86drm.h");
  @cInclude("xf86drmMode.h");
  @cInclude("gbm.h");
  @cInclude("drm_fourcc.h");
});
const Self = @This();

pub const Params = union(enum) {
  fd: std.os.fd_t,
  path: []const u8,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Gpu.init(.{
        .vtable = &.{
          .base = .{},
          .get_egl_display = (struct {
            fn callback(_gpu: *anyopaque) c.EGLDisplay {
              const gpu = Gpu.Type.fromOpaque(_gpu);
              const that = Type.fromOpaque(gpu.type.parent.?);
              return that.getEglDisplay();
            }
          }).callback,
        },
      }, self, t.allocator),
      .fd = try (switch (params) {
        .fd => |fd| std.os.dup(fd),
        .path => |path| std.os.open(path, 0, std.os.O.RDWR),
      }),
      .gbm_dev = try (if (c.gbm_create_device(self.fd)) |value| value else error.GbmFailed),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .fd = try std.os.dup(self.fd),
      .gbm_dev = try (if (c.gbm_create_device(dest.fd)) |value| value else error.GbmFailed),
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    c.gbm_device_destroy(self.gbm_dev);
    std.os.close(self.fd);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Gpu,
fd: std.os.fd_t,
gbm_dev: *c.struct_gbm_device,

pub inline fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return Type.init(params, parent, allocator);
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}

pub fn getEglDisplay(self: *Self) c.EGLDisplay {
  const _clients = c.eglQueryString(c.EGL_NO_DISPLAY, c.EGL_EXTENSIONS);
  var clients: []const u8 = undefined;
  clients.ptr = _clients;
  clients.len = std.mem.len(_clients);

  if (std.mem.containsAtLeast(u8, clients, 1, "EGL_EXT_platform_base")) {
    const eglGetPlatformDisplayEXT = @ptrCast(c.PFNEGLGETPLATFORMDISPLAYEXTPROC, c.eglGetProcAddress("eglGetPlatformDisplayEXT"));
    return eglGetPlatformDisplayEXT.?(c.EGL_PLATFORM_GBM_KHR, self.gbm_dev, null);
  }
  return c.eglGetDisplay(self.gbm_dev);
}
