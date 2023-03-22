const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @This();

fn dupeString(allocator: std.mem.Allocator, value: [*c]const u8, length: c_int) !?[]const u8 {
  if (value == null) {
    return null;
  }

  return try allocator.dupe(u8, value[0..@intCast(usize, length)]);
}

pub const VersionInfo = struct {
  allocator: std.mem.Allocator,
  name: ?[]const u8,
  date: ?[]const u8,
  desc: ?[]const u8,
  value: std.builtin.Version,

  pub fn init(allocator: std.mem.Allocator, value: c.drmVersionPtr) !VersionInfo {
    defer c.drmFreeVersion(value);
    return .{
      .allocator = allocator,
      .name = try dupeString(allocator, value.*.name, value.*.name_len),
      .date = try dupeString(allocator, value.*.date, value.*.date_len),
      .desc = try dupeString(allocator, value.*.desc, value.*.desc_len),
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
path: []const u8,
fd: std.os.fd_t,
version: VersionInfo,
libversion: std.builtin.Version,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !DeviceNode {
  const fd = try std.os.open(path, 0, std.os.linux.O.RDONLY | std.os.linux.O.CLOEXEC);
  return .{
    .allocator = allocator,
    .path = path,
    .fd = fd,
    .version = try VersionInfo.init(allocator, c.drmGetVersion(fd)),
    .libversion = (try VersionInfo.init(allocator, c.drmGetLibVersion(fd))).value,
  };
}

pub fn deinit(self: DeviceNode) void {
  self.version.deinit();
  std.os.close(self.fd);
}

pub fn getCapability(self: DeviceNode, cap: u64) !u64 {
  var value: u64 = 0;
  const ret = c.drmGetCap(self.fd, cap, &value);
  if (ret < 0) {
    try utils.wrapErrno(ret);
    return 0;
  }

  return value;
}
