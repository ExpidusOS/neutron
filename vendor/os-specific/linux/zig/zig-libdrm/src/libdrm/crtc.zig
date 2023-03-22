const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @import("device-node.zig");
const FrameBuffer = @import("fb.zig");
const Crtc = @This();

node: *const DeviceNode,
ptr: c.drmModeCrtcPtr,
id: u32,

pub fn init(node: *const DeviceNode, id: u32) !Crtc {
  return .{
    .node = node,
    .ptr = c.drmModeGetCrtc(node.fd, id),
    .id = id,
  };
}

pub fn deinit(self: Crtc) void {
  c.drmModeFreeCrtc(self.ptr);
}

pub fn addFrameBuffer(self: Crtc, width: u32, height: u32, depth: u8, bpp: u8, pitch: u32) !FrameBuffer {
  if (self.ptr.*.buffer_id == 0) return error.InputOutput;

  var id: u32 = 0;
  const ret = c.drmModeAddFB(self.node.fd, width, height, depth, bpp, pitch, self.ptr.*.buffer_id, &id);
  try utils.catchError(ret);

  const ptr = c.drmModeGetFB(self.node.fd, id);
  if (ptr == null) {
    _ = c.drmModeRmFB(self.node.fd, id);
    return error.InputOutput;
  }

  defer c.drmModeFreeFB(ptr);
  return FrameBuffer.init(&self, ptr);
}
