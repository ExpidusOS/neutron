const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @import("device-node.zig");
const DumbFrameBuffer = @import("fb.zig").DumbFrameBuffer;
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

pub fn createDumbFrameBuffer(self: Crtc, comptime S: type, width: u32, height: u32) !DumbFrameBuffer(S) {
  const size_type_info = @typeInfo(S);
  if (size_type_info != .Int) @compileError("Size must be an integer");
  const bpp = size_type_info.Int.bits;

  var handle: u32 = 0;
  var pitch: u32 = 0;
  var size: u64 = 0;

  var ret = c.drmModeCreateDumbBuffer(self.node.fd, width, height, bpp, 0, &handle, &pitch, &size);
  try utils.catchErrno(ret);
  errdefer _ = c.drmModeDestroyDumbBuffer(self.node.fd, handle);

  var offset: u64 = 0;
  ret = c.drmModeMapDumbBuffer(self.node.fd, handle, &offset);
  try utils.catchErrno(ret);

  const addr = std.os.linux.mmap(null, size,
    std.os.linux.PROT.READ | std.os.linux.PROT.WRITE,
    std.os.linux.MAP.SHARED, self.node.fd, @intCast(i64, offset));
  if (addr == -1) {
    try utils.catchError(c.__errno_location().*);
  }

  return DumbFrameBuffer(S).init(&self, width, height, handle, pitch, addr, size);
}
