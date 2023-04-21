const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const hardware = @import("../../hardware.zig");
const Context = @import("../base/context.zig");
const eglApi = @import("../../graphics/api/egl.zig");
const Self = @This();

const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {
  wlr_buffer: *wlr.Buffer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .buffer = params.wlr_buffer,
      .base = try graphics.FrameBuffer.init(.{
        .vtable = &self.vtable,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .buffer = self.buffer,
      .base = try self.base.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }

  pub fn destroy(self: *Self) void {
    self.buffer.drop();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
buffer: *wlr.Buffer,
base: graphics.FrameBuffer,
vtable: graphics.FrameBuffer.VTable = .{
  .get_resolution = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "vtable", base.value.vtable);
      return .{
        self.buffer.width,
        self.buffer.height,
      };
    }
  }).callback,
  .get_stride = (struct {
    fn callback(_base: *anyopaque) u32 {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "vtable", base.value.vtable);

      var dmabuf: wlr.DmabufAttributes = undefined;
      if (self.buffer.getDmabuf(&dmabuf)) {
        return dmabuf.stride[0];
      }

      var shm: wlr.ShmAttributes = undefined;
      if (self.buffer.getShm(&shm)) {
        return @intCast(u32, shm.stride);
      }

      var buffer: *anyopaque = undefined;
      var format: u32 = undefined;
      var stride: usize = undefined;
      if (self.buffer.beginDataPtrAccess(0, &buffer, &format, &stride)) {
        self.buffer.endDataPtrAccess();
        return @intCast(u32, stride);
      }

      return 0;
    }
  }).callback,
  .get_format = (struct {
    fn callback(_base: *anyopaque) u32 {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "vtable", base.value.vtable);

      var dmabuf: wlr.DmabufAttributes = undefined;
      if (self.buffer.getDmabuf(&dmabuf)) {
        return dmabuf.format;
      }

      var shm: wlr.ShmAttributes = undefined;
      if (self.buffer.getShm(&shm)) {
        return shm.format;
      }

      var buffer: *anyopaque = undefined;
      var format: u32 = undefined;
      var stride: usize = undefined;
      if (self.buffer.beginDataPtrAccess(0, &buffer, &format, &stride)) {
        self.buffer.endDataPtrAccess();
        return format;
      }

      return 0;
    }
  }).callback,
  .get_buffer = (struct {
    fn callback(_base: *anyopaque) !*anyopaque {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "vtable", base.value.vtable);

      var buffer: *anyopaque = undefined;
      var format: u32 = undefined;
      var stride: usize = undefined;
      if (self.buffer.beginDataPtrAccess(0, &buffer, &format, &stride)) {
        return buffer;
      }
      return error.BufferFailed;
    }
  }).callback,
  .commit = (struct {
    fn callback(_base: *anyopaque) !void {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = @fieldParentPtr(Self, "vtable", base.value.vtable);
      self.buffer.endDataPtrAccess();
    }
  }).callback,
},

pub usingnamespace Type.Impl;

pub fn getEGLImageKHRParameters(self: *Self) !Context.EGLImageKHRParameters {
  var dmabuf: wlr.DmabufAttributes = undefined;
  if (!self.buffer.getDmabuf(&dmabuf)) return error.DmabufError;

  var attribs = [_]i32 {eglApi.c.EGL_NONE} ** 50;
  var x: usize = 0;

  attribs[x] = eglApi.c.EGL_WIDTH;
  x += 1;

  attribs[x] = self.buffer.width;
  x += 1;

  attribs[x] = eglApi.c.EGL_HEIGHT;
  x += 1;

  attribs[x] = self.buffer.height;
  x += 1;

  attribs[x] = eglApi.c.EGL_LINUX_DRM_FOURCC_EXT;
  x += 1;

  attribs[x] = @intCast(i32, dmabuf.format);
  x += 1;

  const names = .{ "0", "1", "2", "3", };
  inline for (dmabuf.offset, dmabuf.stride, dmabuf.fd, names, 0..) |offset, stride, fd, name, i| {
    if (i >= dmabuf.n_planes) break;

    attribs[x] = @field(eglApi.c, "EGL_DMA_BUF_PLANE" ++ name ++ "_FD_EXT");
    x += 1;

    attribs[x] = fd;
    x += 1;

    attribs[x] = @field(eglApi.c, "EGL_DMA_BUF_PLANE" ++ name ++ "_OFFSET_EXT");
    x += 1;

    attribs[x] = @intCast(i32, offset);
    x += 1;

    attribs[x] = @field(eglApi.c, "EGL_DMA_BUF_PLANE" ++ name ++ "_PITCH_EXT");
    x += 1;

    attribs[x] = @intCast(i32, stride);
    x += 1;

    if (dmabuf.modifier != 0) {
      attribs[x] = @field(eglApi.c, "EGL_DMA_BUF_PLANE" ++ name ++ "_MODIFIER_LO_EXT");
      x += 1;

      attribs[x] = @intCast(i32, dmabuf.modifier & 0xFFFFFFFF);
      x += 1;

      attribs[x] = @field(eglApi.c, "EGL_DMA_BUF_PLANE" ++ name ++ "_MODIFIER_HI_EXT");
      x += 1;

      attribs[x] = @intCast(i32, dmabuf.modifier >> 32);
      x += 1;
    }
  }

  attribs[x] = eglApi.c.EGL_IMAGE_PRESERVED_KHR;
  x += 1;

  attribs[x] = eglApi.c.EGL_TRUE;
  x += 1;

  return Context.EGLImageKHRParameters {
    .target = eglApi.c.EGL_LINUX_DMA_BUF_EXT,
    .buffer = null,
    .attribs = &attribs,
  };
}
