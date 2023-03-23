const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const Crtc = @import("crtc.zig");

pub fn DumbFrameBuffer(comptime S: type) type {
  if (@typeInfo(S) != .Int) @compileError("Size must be an integer");
  return struct {
    const Self = @This();

    crtc: *const Crtc,
    handle: u32,
    width: u32,
    height: u32,
    pitch: u32,
    size: u64,
    address: usize,
    buffer: [*]S,

    pub fn init(crtc: *const Crtc, width: u32, height: u32, handle: u32, pitch: u32, address: usize, size: u64) Self {
      return .{
        .crtc = crtc,
        .handle = handle,
        .width = width,
        .height = height,
        .pitch = pitch,
        .address = address,
        .size = size,
        .buffer = @ptrCast([*]S, @constCast(&address)),
      };
    }

    pub fn destroy(self: Self) void {
      // TODO: we should panic if these fail
      _ = std.os.linux.munmap(@ptrCast([*]const u8, self.buffer), self.size);
      _ = c.drmModeDestroyDumbBuffer(self.crtc.node.fd, self.handle);
    }
  };
}
