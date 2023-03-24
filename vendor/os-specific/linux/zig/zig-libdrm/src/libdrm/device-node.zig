const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const Crtc = @import("crtc.zig");
const Connector = @import("connector.zig");
const Encoder = @import("encoder.zig");
const FrameBuffer2 = @import("fb.zig").FrameBuffer2;
const Plane = @import("plane.zig");
const DeviceNode = @This();

fn dupeString(alloc: std.mem.Allocator, value: [*c]const u8, length: c_int) !?[]const u8 {
  if (value == null or length == 0) {
    return null;
  }

  return try alloc.dupe(u8, value[0..@intCast(usize, length)]);
}

pub const VersionInfo = struct {
  allocator: std.mem.Allocator,
  name: ?[]const u8,
  date: ?[]const u8,
  desc: ?[]const u8,
  value: std.builtin.Version,

  pub fn init(alloc: std.mem.Allocator, value: c.drmVersionPtr) !VersionInfo {
    defer c.drmFreeVersion(value);
    return .{
      .allocator = alloc,
      .name = try dupeString(alloc, value.*.name, value.*.name_len),
      .date = try dupeString(alloc, value.*.date, value.*.date_len),
      .desc = try dupeString(alloc, value.*.desc, value.*.desc_len),
      .value = .{
        .major = @intCast(u32, value.*.version_major),
        .minor = @intCast(u32, value.*.version_minor),
        .patch = @intCast(u32, value.*.version_patchlevel),
      },
    };
  }

  pub fn deinit(self: VersionInfo) void {
    if (self.name) |value| {
      self.allocator.free(value);
    }

    if (self.date) |value| {
      self.allocator.free(value);
    }

    if (self.desc) |value| {
      self.allocator.free(value);
    }
  }
};

allocator: std.mem.Allocator,
allocs: std.AutoHashMap(usize, c.drm_magic_t),
fd: std.os.fd_t,
version: VersionInfo,
libversion: std.builtin.Version,
is_kms: bool,
path: []const u8,

pub fn init(alloc: std.mem.Allocator, path: []const u8) !*DeviceNode {
  const fd = try std.os.open(path, 0, std.os.linux.O.RDONLY | std.os.linux.O.CLOEXEC);
  const self = try alloc.create(DeviceNode);
  self.* = .{
    .allocator = alloc,
    .allocs = std.AutoHashMap(usize, c.drm_magic_t).init(alloc),
    .path = path,
    .fd = fd,
    .version = try VersionInfo.init(alloc, c.drmGetVersion(fd)),
    .libversion = (try VersionInfo.init(alloc, c.drmGetLibVersion(fd))).value,
    .is_kms = c.drmIsKMS(fd) == 1,
  };
  return self;
}

pub fn deinit(self: *DeviceNode) void {
  self.version.deinit();
  std.os.close(self.fd);
  self.allocator.destroy(self);
}

pub fn getCapability(self: *DeviceNode, cap: u64) !u64 {
  var value: u64 = 0;
  const ret = c.drmGetCap(self.fd, cap, &value);
  if (ret < 0) {
    try utils.wrapErrno(ret);
    return 0;
  }

  return value;
}

pub fn getCrtcs(self: *DeviceNode) ![]*Crtc {
  const res = c.drmModeGetResources(self.fd);
  if (res == null) {
    return error.InputOutput;
  }

  defer c.drmModeFreeResources(res);

  const crtcs = try self.allocator.alloc(*Crtc, @intCast(usize, res.*.count_crtcs));
  for (crtcs, res.*.crtcs[0..@intCast(usize, res.*.count_crtcs)]) |*value, id| {
    value.* = try Crtc.init(self, id);
  }
  return crtcs;
}

pub fn getConnectors(self: *DeviceNode) ![]*Connector {
  const res = c.drmModeGetResources(self.fd);
  if (res == null) {
    return error.InputOutput;
  }

  defer c.drmModeFreeResources(res);

  const connectors = try self.allocator.alloc(*Connector, @intCast(usize, res.*.count_connectors));
  for (connectors, res.*.connectors[0..@intCast(usize, res.*.count_connectors)]) |*value, id| {
    value.* = try Connector.init(self, id);
  }
  return connectors;
}

pub fn getEncoders(self: *DeviceNode) ![]*Encoder {
  const res = c.drmModeGetResources(self.fd);
  if (res == null) {
    return error.InputOutput;
  }

  defer c.drmModeFreeResources(res);

  const encoders = try self.allocator.alloc(*Encoder, @intCast(usize, res.*.count_encoders));
  for (encoders, res.*.encoders[0..@intCast(usize, res.*.count_encoders)]) |*value, id| {
    value.* = try Encoder.init(self, id);
  }
  return encoders;
}

pub fn getPlanes(self: *DeviceNode) ![]*Plane {
  const res = c.drmModeGetPlaneResources(self.fd);
  if (res == null) {
    return error.InputOutput;
  }

  defer c.drmModeFreePlaneResources(res);

  const planes = try self.allocator.alloc(*Plane, @intCast(usize, res.*.count_planes));
  for (planes, res.*.planes[0..@intCast(usize, res.*.count_planes)]) |*value, id| {
    value.* = try Plane.init(self, id);
  }
  return planes;
}

pub fn createFrameBuffer2(self: *DeviceNode, comptime S: type, width: u32, height: u32, format: u32, handles: [4]u32, pitches: [4]u32, offsets: [4]u32) !FrameBuffer2(S) {
  var id: u32 = 0;
  var ret = c.drmModeAddFB2(self.fd, width, height, format, handles, pitches, offsets, &id, 0);
  try utils.catchErrno(ret);
  errdefer _ = c.drmModeRmFB(self.fd, id);

  const ptr = c.drmModeGetFB2(self.fd, id);
  if (ptr == null) {
    return error.InvalidResource;
  }

  errdefer c.drmModeFreeFB2(ptr);
  return FrameBuffer2(S).init(self, ptr);
}

pub fn isMaster(self: *DeviceNode) bool {
  return c.drmIsMaster(self.fd) == 1;
}

pub fn setMaster(self: *DeviceNode, value: bool) !void {
  const ret = if (value) c.drmSetMaster(self.fd) else c.drmDropMaster(self.fd);
  try utils.catchErrno(ret);
}

pub fn getAllocator(self: *DeviceNode) std.mem.Allocator {
  return .{
    .ptr = self,
    .vtable = &.{
      .alloc = allocator_alloc,
      .resize = allocator_resize,
      .free = allocator_free,
    },
  };
}

fn allocator_alloc(_self: *anyopaque, n: usize, log2_align: u8, ra: usize) ?[*]u8 {
  const self = @ptrCast(*DeviceNode, @alignCast(@alignOf(DeviceNode), _self));

  std.debug.assert(n > 0);
  if (n > std.math.maxInt(usize) - (std.mem.page_size - 1)) return null;
  const aligned_len = std.mem.alignForward(n, std.mem.page_size);

  var handle: c.drm_handle_t = 0;
  var ret = c.drmAddMap(self.fd, 0, @intCast(c_uint, aligned_len), c.DRM_SHM, 0, &handle);
  utils.catchErrno(ret) catch @panic("Cannot handle errors in alloc");
  errdefer _ = c.drmRmMap(self.fd, handle);

  const addr = self.allocator.rawAlloc(aligned_len, log2_align, ra);
  if (addr == null) @panic("Cannot handle alllocation failure");
  errdefer self.allocator.rawFree(addr, log2_align, ra);

  ret = c.drmMap(self.fd, handle, @intCast(c_uint, aligned_len), @ptrCast([*c]?*anyopaque, @constCast(&addr)));
  utils.catchErrno(ret) catch @panic("Cannot handle errors in alloc");
  errdefer _ = self.drmUnmap(addr, aligned_len);

  self.allocs.put(@ptrToInt(addr), handle) catch @panic("Failed to update allocation map");
  return addr;
}

fn allocator_resize(_self: *anyopaque, buff: []u8, log2_align: u8, n: usize, ra: usize) bool {
  const self = @ptrCast(*DeviceNode, @alignCast(@alignOf(DeviceNode), _self));

  std.debug.assert(n > 0);
  if (n > std.math.maxInt(usize) - (std.mem.page_size - 1)) return false;
  const aligned_len = std.mem.alignForward(n, std.mem.page_size);

  const addr = @ptrToInt(@ptrCast([*]u8, buff));
  var handle = self.allocs.get(addr) orelse @panic("Failed to get from allocation map");
  _ = self.allocs.remove(addr);
  errdefer self.allocator.rawFree(buff, log2_align, ra);

  _ = c.drmUnmap(@ptrCast(*anyopaque, @constCast(buff)), @intCast(c_uint, buff.len));
  _ = c.drmRmMap(self.fd, handle);

  handle = 0;

  var ret = c.drmAddMap(self.fd, 0, @intCast(c_uint, aligned_len), c.DRM_SHM, 0, &handle);
  utils.catchErrno(ret) catch @panic("Cannot handle errors in alloc");
  errdefer _ = c.drmRmMap(self.fd, handle);

  ret = c.drmMap(self.fd, handle, @intCast(c_uint, aligned_len), @ptrCast([*c]?*anyopaque, @constCast(&addr)));
  utils.catchErrno(ret) catch @panic("Cannot handle errors in alloc");
  errdefer _ = self.drmUnmap(addr, aligned_len);

  self.allocs.put(addr, handle) catch @panic("Failed to update allocation map");
  return true;
}

fn allocator_free(_self: *anyopaque, buff: []u8, log2_align: u8, ra: usize) void {
  const self = @ptrCast(*DeviceNode, @alignCast(@alignOf(DeviceNode), _self));

  const addr = @ptrToInt(@ptrCast([*]u8, buff));
  const handle = self.allocs.get(addr) orelse @panic("Failed to get from allocation map");
  _ = self.allocs.remove(addr);

  _ = c.drmUnmap(@ptrCast(*anyopaque, @constCast(buff)), @intCast(c_uint, buff.len));
  _ = c.drmRmMap(self.fd, handle);
  self.allocator.rawFree(buff, log2_align, ra);
}
