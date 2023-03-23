const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const color = @import("color.zig");
const Connector = @import("connector.zig");
const DeviceNode = @import("device-node.zig");
const DumbFrameBuffer = @import("fb.zig").DumbFrameBuffer;
const Mode = @import("mode.zig");
const Crtc = @This();

node: *const DeviceNode,
ptr: c.drmModeCrtcPtr,
id: u32,

pub fn init(node: *const DeviceNode, id: u32) !*Crtc {
  const self = try node.allocator.create(Crtc);
  self.* = .{
    .node = node,
    .ptr = c.drmModeGetCrtc(node.fd, id),
    .id = id,
  };
  return self;
}

pub fn deinit(self: *Crtc) void {
  c.drmModeFreeCrtc(self.ptr);
  self.node.allocator.destroy(self);
}

pub fn createDumbFrameBuffer(self: *const Crtc, comptime S: type, width: u32, height: u32) !DumbFrameBuffer(S) {
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

  return DumbFrameBuffer(S).init(self, width, height, handle, pitch, addr, size);
}

pub fn setGamma(self: *const Crtc, value: color.U16Color) !void {
  const ret = c.drmModeCrtcSetGamma(self.node.fd, self.id, color.U16Color.full_size, &value.red, &value.green, &value.blue);
  try utils.catchErrno(ret);
}

pub fn getGamma(self: *const Crtc) !color.U16Color {
  var value = color.U16Color.init();
  const ret = c.drmModeCrtcGetGamma(self.node.fd, self.id, color.U16Color.full_size, &value.red, &value.green, &value.blue);
  try utils.catchErrno(ret);
  return value;
}

pub fn set(self: *const Crtc, connectors: []Connector, buffer: anytype, mode: Mode) !void {
  const tmp_connectors = try self.node.allocator.alloc(u32, connectors.len);
  defer self.node.allocator.free(tmp_connectors);

  for (tmp_connectors, connectors) |*v, conn| {
    v.* = conn.id;
  }

  const ret = c.drmModeSetCrtc(self.node.fd, self.id, buffer.handle, 0, 0, tmp_connectors, tmp_connectors.len, &mode.@"export"());
  try utils.catchError(ret);
}
