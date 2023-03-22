const std = @import("std");
const assert = std.debug.assert;
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @import("device-node.zig");
const Device = @This();

ptr: ?*c.drmDevice,

pub fn init(ptr: c.drmDevicePtr) Device {
  return .{
    .ptr = ptr,
  };
}

pub fn fromDevId(dev_id: u32, flags: u32) !Device {
  const ptr: c.drmDevicePtr = undefined;
  const ret = c.drmGetDeviceFromDevId(dev_id, flags, &ptr);
  if (ret < 0) {
    return utils.wrapErrno(ret);
  }

  return .{
    .ptr = ptr,
  };
}

pub fn isEqual(a: Device, b: Device) bool {
  assert(a.ptr != null);
  assert(b.ptr != null);
  return c.drmDeviceEqual(a.ptr, b.ptr);
}

pub fn deinit(self: Device) void {
  c.drmFreeDevice(@ptrCast([*c]c.drmDevicePtr, @constCast(&self.ptr.?)));
}

pub fn getNodes(self: Device) ![c.DRM_NODE_MAX]?DeviceNode {
  assert(self.ptr != null);
  const device = self.ptr.?;

  var list = [c.DRM_NODE_MAX]?DeviceNode { null, null, null };
  inline for (&list, 0..) |*item, i| {
    if ((device.*.available_nodes & 1 << i) == 1) {
      item.* = try self.getNode(i);
    } else {
      item.* = null;
    }
  }
  return list;
}

pub fn getNode(self: Device, i: u3) !DeviceNode {
  assert(i < c.DRM_NODE_MAX);
  assert(self.ptr != null);
  const device = self.ptr.?;

  if ((device.*.available_nodes & @as(u8, 1) << i) == 1) {
    var len: usize = 0;
    const str = device.*.nodes[i];
    while (str[len] != 0) : (len += 1) {}
    return try DeviceNode.init(str[0..len]);
  }

  return error.InputOutput;
}
