const std = @import("std");
const assert = std.debug.assert;
const utils = @import("utils.zig");
const c = @import("c.zig").c;

pub const Device = @import("libdrm/device.zig");
pub const DeviceNode = @import("libdrm/device-node.zig");

pub const DrmError = error {
  NoDevices,
};

pub fn isAvailable() bool {
  return c.drmAvailable();
}

fn wrappedGetDevices2(flags: u32, devices: [*c]c.drmDevicePtr, max_devices: ?usize) !usize {
  const max_devices_pass = if (max_devices == null) 0 else @intCast(c_int, max_devices.?);
  const n_devices = c.drmGetDevices2(flags, devices, max_devices_pass);
  if (n_devices < 0) {
    return utils.wrapErrno(n_devices);
  }
  return @intCast(usize, n_devices);
}

pub fn getDevices2(allocator: std.mem.Allocator, flags: u32, dest: []Device) !void {
  const n_devices = try wrappedGetDevices2(flags, null, dest.len);

  assert(n_devices == dest.len);
  const devices = try allocator.alloc(c.drmDevicePtr, n_devices);
  defer allocator.free(devices);

  _ = try wrappedGetDevices2(flags, @ptrCast([*c]c.drmDevicePtr, devices), n_devices);

  for (dest, devices) |*item, dev| {
    item.* = Device.init(allocator, dev);
  }
}

pub fn getDevices2Alloc(allocator: std.mem.Allocator, flags: u32) ![]const Device {
  const n_devices = try wrappedGetDevices2(flags, null, 0);
  var list = try allocator.alloc(Device, @intCast(usize, n_devices));
  try getDevices2(allocator, flags, list);
  return list;
}

pub fn freeDevices(allocator: std.mem.Allocator, list: []const Device) void {
  for (list) |item| {
    item.deinit();
  }

  allocator.free(list);
}
