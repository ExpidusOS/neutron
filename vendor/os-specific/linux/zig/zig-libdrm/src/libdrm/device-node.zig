const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @This();

path: []const u8,
fd: std.os.fd_t,

pub fn init(path: []const u8) !DeviceNode {
  const fd = try std.os.open(path, 0, std.os.linux.O.RDONLY | std.os.linux.O.CLOEXEC);
  return .{
    .path = path,
    .fd = fd,
  };
}

pub fn deinit(self: DeviceNode) void {
  std.os.close(self.fd);
}
