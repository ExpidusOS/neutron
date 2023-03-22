const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const Crtc = @import("crtc.zig");
const FrameBuffer = @This();

crtc: *const Crtc,
fb_id: u32,
width: u32,
height: u32,
pitch: u32,
bpp: u32,
handle: u32,

pub fn init(crtc: *const Crtc, ptr: c.drmModeFBPtr) FrameBuffer {
  return .{
    .crtc = crtc,
    .fb_id = ptr.*.fb_id,
    .width = ptr.*.width,
    .height = ptr.*.height,
    .pitch = ptr.*.pitch,
    .bpp = ptr.*.bpp,
    .handle = ptr.*.handle,
  };
}

pub fn @"export"(self: FrameBuffer) c.drmModeFB {
  return .{
    .fb_id = self.fb_id,
    .width = self.width,
    .height = self.height,
    .pitch = self.pitch,
    .bpp = self.bpp,
    .handle = self.handle,
  };
}

pub fn dirty(self: FrameBuffer, clips: []c.drmModeClip) !void {
  const ret = c.drmModeDirtyFB(self.crtc.node.fd, self.handle, clips, clips.len);
  if (ret < 0) {
    try utils.wrapErrno(ret);
  }
}

pub fn destroy(self: FrameBuffer) void {
  const ret = c.drmModeRmFB(self.crtc.node.fd, self.handle);
  if (ret < 0) {
    @panic("Failed to destroy frame buffer");
  }
}
