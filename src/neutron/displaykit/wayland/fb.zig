const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const hardware = @import("../../hardware.zig");
const Client = @import("client.zig");
const Self = @This();

const wl = @import("wayland").client.wl;

const vtable = graphics.FrameBuffer.VTable {
  .get_resolution = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.resolution;
    }
  }).callback,
  .get_stride = (struct {
    fn callback(_base: *anyopaque) u32 {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return @intCast(u32, self.resolution[0] * self.depth);
    }
  }).callback,
  .get_format = (struct {
    fn callback(_base: *anyopaque) u32 {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return @intCast(u32, @enumToInt(self.format));
    }
  }).callback,
  .get_buffer = (struct {
    fn callback(_base: *anyopaque) !*anyopaque {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return @ptrCast(*anyopaque, @alignCast(@alignOf(anyopaque), self.buffer));
    }
  }).callback,
  .commit = (struct {
    fn callback(_base: *anyopaque) !void {
      const base = graphics.FrameBuffer.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());

      const size = self.resolution[0] * self.resolution[1];
      const buffer = @ptrCast([*]u32, @alignCast(@alignOf([]u32), self.buffer));

      var i: usize = 0;
      while (i < size) : (i += 1) {
        const pixel = buffer[i];

        const red = (pixel & 0xff000000) >> 24;
        const green = (pixel & 0x00ff0000) >> 16;
        const blue = (pixel & 0x0000ff00) >> 8;
        const alpha = (pixel & 0x000000ff) << 24;

        buffer[i] = alpha | red | green | blue;
      }
    }
  }).callback,
};

pub const Params = struct {
  client: *Client,
  resolution: @Vector(2, i32),
  depth: i8,
  format: wl.Shm.Format,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    const name = try std.fmt.allocPrint(t.allocator, "neutron-fb-{}x{}-{}-{x}", .{ params.resolution[0], params.resolution[1], params.depth, @ptrToInt(self) });
    defer t.allocator.free(name);

    const stride = params.resolution[0] * params.depth;
    const size = params.resolution[1] * stride;

    const fd = try std.os.memfd_create(name, 0);
    try std.os.ftruncate(fd, @intCast(u64, size));

    self.* = .{
      .type = t,
      .client = params.client,
      .base = undefined,
      .resolution = params.resolution,
      .depth = params.depth,
      .format = params.format,
      .fd = fd,
      .buffer = try std.os.mmap(null, @intCast(usize, size), std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.SHARED, fd, 0),
      .pool = try params.client.shm.?.createPool(fd, size),
      .wl_buffer = try self.pool.createBuffer(0, params.resolution[0], params.resolution[1], stride, params.format),
    };

    _ = try graphics.FrameBuffer.init(&self.base, .{
     .vtable = &vtable,
    }, self, t.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .client = self.client,
      .base = undefined,
      .resolution = self.resolution,
      .depth = self.depth,
      .format = self.format,
      .fd = self.fd,
      .buffer = self.buffer,
      .pool = self.pool,
      .wl_buffer = self.wl_buffer,
    };

    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }

  pub fn destroy(self: *Self) void {
    self.wl_buffer.destroy();
    self.pool.destroy();
    std.os.close(self.fd);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
client: *Client,
base: graphics.FrameBuffer,
resolution: @Vector(2, i32),
depth: i8,
format: wl.Shm.Format,
fd: std.os.fd_t,
buffer: []align(std.mem.page_size) u8,
pool: *wl.ShmPool,
wl_buffer: *wl.Buffer,

pub usingnamespace Type.Impl;
