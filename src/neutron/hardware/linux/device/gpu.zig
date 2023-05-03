const std = @import("std");
const elemental = @import("../../../elemental.zig");
const graphics = @import("../../../graphics.zig");
const Gpu = @import("../../base/device/gpu.zig");
const Self = @This();

pub const c = @cImport({
  @cInclude("EGL/egl.h");
  @cInclude("EGL/eglext.h");
  @cInclude("xf86drm.h");
  @cInclude("xf86drmMode.h");
  @cInclude("gbm.h");
  @cInclude("drm_fourcc.h");
});

pub const FrameBuffer = struct {
  pub const Params = struct {
    gbm_bo: *c.struct_gbm_bo,
  };

  const Impl = struct {
    pub fn construct(self: *FrameBuffer, params: FrameBuffer.Params, t: FrameBuffer.Type) !void {
      var stride: u32 = undefined;
      var map_data: ?*anyopaque = null;

      self.* = .{
        .type = t,
        .gbm_bo = params.gbm_bo,
        .stride = stride,
        .buffer = try (if (c.gbm_bo_map(
            params.gbm_bo,
            0, 0,
            c.gbm_bo_get_width(params.gbm_bo),
            c.gbm_bo_get_height(params.gbm_bo),
            0, &stride, &map_data
          )) |value| value else error.GbmMapFailure),
        .base = try graphics.FrameBuffer.init(.{
          .vtable = &.{
            .get_resolution = (struct {
              fn callback(_fb: *anyopaque) @Vector(2, i32) {
                const bfb = graphics.FrameBuffer.Type.fromOpaque(_fb);
                const fb = @fieldParentPtr(FrameBuffer, "base", bfb);
                return .{
                  @intCast(i32, c.gbm_bo_get_width(fb.gbm_bo)),
                  @intCast(i32, c.gbm_bo_get_height(fb.gbm_bo)),
                };
              }
            }).callback,
            .get_stride = (struct {
              fn callback(_fb: *anyopaque) u32 {
                const bfb = graphics.FrameBuffer.Type.fromOpaque(_fb);
                const fb = @fieldParentPtr(FrameBuffer, "base", bfb);
                return fb.stride;
              }
            }).callback,
            .get_format = (struct {
              fn callback(_fb: *anyopaque) u32 {
                const bfb = graphics.FrameBuffer.Type.fromOpaque(_fb);
                const fb = @fieldParentPtr(FrameBuffer, "base", bfb);
                return c.gbm_bo_get_format(fb.gbm_bo);
              }
            }).callback,
            .get_bpp = (struct {
              fn callback(_fb: *anyopaque) u32 {
                const bfb = graphics.FrameBuffer.Type.fromOpaque(_fb);
                const fb = @fieldParentPtr(FrameBuffer, "base", bfb);
                return c.gbm_bo_get_bpp(fb.gbm_bo);
              }
            }).callback,
            .get_buffer = (struct {
              fn callback(_fb: *anyopaque) *anyopaque {
                const bfb = graphics.FrameBuffer.Type.fromOpaque(_fb);
                const fb = @fieldParentPtr(FrameBuffer, "base", bfb);
                return fb.buffer;
              }
            }).callback,
          },
        }, self, t.allocator),
      };
    }

    pub fn ref(self: *FrameBuffer, dest: *FrameBuffer, t: FrameBuffer.Type) !void {
      dest.* = .{
        .type = t,
        .base = try self.base.type.refInit(t.allocator),
        .stride = self.stride,
        .gbm_bo = self.gbm_bo,
        .buffer = self.buffer,
      };
    }

    pub fn unref(self: *FrameBuffer) void {
      self.base.unref();
    }

    pub fn destroy(self: *FrameBuffer) void {
      c.gbm_bo_unmap(self.gbm_bo, self.buffer);
      c.gbm_bo_set_user_data(self.gbm_bo, null, null);
    }
  };

  pub const Type = elemental.Type(FrameBuffer, FrameBuffer.Params, FrameBuffer.Impl);

  @"type": FrameBuffer.Type,
  base: graphics.FrameBuffer,
  stride: u32,
  gbm_bo: *c.struct_gbm_bo,
  buffer: *anyopaque,
};

pub const Params = union(enum) {
  fd: std.os.fd_t,
  path: []const u8,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = undefined,
      .fd = try (switch (params) {
        .fd => |fd| std.os.dup(fd),
        .path => |path| std.os.open(path, 0, std.os.O.RDWR),
      }),
      .gbm_dev = try (if (c.gbm_create_device(self.fd)) |value| value else error.GbmFailed),
    };

    _ = try Gpu.init(&self.base, .{
      .vtable = &.{
        .base = .{},
        .get_egl_display = (struct {
          fn callback(_gpu: *anyopaque) !c.EGLDisplay {
            const gpu = Gpu.Type.fromOpaque(_gpu);
            const that = Type.fromOpaque(gpu.type.parent.?.getValue());
            return that.getEglDisplay();
          }
        }).callback,
      },
    }, self, t.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = undefined,
      .fd = try std.os.dup(self.fd),
      .gbm_dev = try (if (c.gbm_create_device(dest.fd)) |value| value else error.GbmFailed),
    };

    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    c.gbm_device_destroy(@ptrCast(*c.struct_gbm_device, self.gbm_dev));
    std.os.close(self.fd);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Gpu,
fd: std.os.fd_t,
gbm_dev: *anyopaque,

pub usingnamespace Type.Impl;

pub fn getEglDisplay(self: *Self) !c.EGLDisplay {
  const _clients = c.eglQueryString(c.EGL_NO_DISPLAY, c.EGL_EXTENSIONS);
  var clients: []const u8 = undefined;
  clients.ptr = _clients;
  clients.len = std.mem.len(_clients);

  if (std.mem.containsAtLeast(u8, clients, 1, "EGL_EXT_platform_base")) {
    const eglGetPlatformDisplayEXT = @ptrCast(c.PFNEGLGETPLATFORMDISPLAYEXTPROC, c.eglGetProcAddress("eglGetPlatformDisplayEXT"));
    const display = eglGetPlatformDisplayEXT.?(c.EGL_PLATFORM_GBM_KHR, self.gbm_dev, null);
    if (display == c.EGL_NO_DISPLAY) return error.NoEglDisplay;
    return display;
  }

  const display = c.eglGetDisplay(self.gbm_dev);
  if (display == c.EGL_NO_DISPLAY) return error.NoEglDisplay;
  return display;
}

fn gbm_bo_unref(gbm_bo: ?*c.struct_gbm_bo, userdata: ?*anyopaque) callconv(.C) void {
  _ = gbm_bo;
  FrameBuffer.Type.fromOpaque(userdata.?).type.unref();
}

pub fn getGBMFrameBuffer(self: *Self, gbm_bo: *c.struct_gbm_bo) !*graphics.FrameBuffer {
  return if (c.gbm_bo_get_user_data(gbm_bo)) |value| &(@ptrCast(*FrameBuffer, @alignCast(@alignOf(*FrameBuffer), value))).base
    else blk: {
      const value = try FrameBuffer.Type.new(.{
        .gbm_bo = gbm_bo,
      }, self, self.type.allocator);
      c.gbm_bo_set_user_data(gbm_bo, value, gbm_bo_unref);
      break :blk &value.base;
    };
}
