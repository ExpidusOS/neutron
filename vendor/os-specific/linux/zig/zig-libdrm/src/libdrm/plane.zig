const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @import("device-node.zig");
const Crtc = @import("crtc.zig");
const fb = @import("fb.zig");
const Plane = @This();

node: *DeviceNode,
ptr: c.drmModePlanePtr,
id: u32,

pub fn init(node: *DeviceNode, id: u32) !*Plane {
  const ptr = c.drmModeGetPlane(node.fd, id);
  if (ptr == null) {
    return error.InputOutput;
  }

  const self = try node.allocator.create(Plane);
  self.* = .{
    .node = node,
    .ptr = ptr,
    .id = id,
  };
  return self;
}

pub fn deinit(self: *Plane) void {
  c.drmModeFreePlane(self.ptr);
  self.node.allocator.destroy(self);
}

pub fn getPossibleCrtcs(self: *Plane) ![]*Crtc {
  const res = c.drmModeGetResources(self.node.fd);
  if (res == null) {
    return error.InputOutput;
  }

  defer c.drmModeFreeResources(res);

  var count: usize = 0;
  for (res.*.crtcs[0..@intCast(usize, res.*.count_crtcs)], 0..) |_, i| {
    if ((self.ptr.*.possible_crtcs & @as(u32, 1) << @intCast(u5, i)) == 1) {
      count += 1;
    }
  }

  const crtcs = try self.node.allocator.alloc(*Crtc, count);
  var i: usize = 0;
  for (res.*.crtcs[0..@intCast(usize, res.*.count_crtcs)], 0..) |id, x| {
    if ((self.ptr.*.possible_crtcs & @as(u32, 1) << @intCast(u5, x)) == 1) {
      crtcs[i] = try Crtc.init(self.node, id);
      i += 1;
    }
  }
  return crtcs;
}
