const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const Crtc = @import("crtc.zig");
const DeviceNode = @import("device-node.zig");
const Plane = @import("plane.zig");

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

pub fn FrameBuffer2(comptime S: type) type {
  if (@typeInfo(S) != .Int) @compileError("Size must be an integer");
  return struct {
    const Self = @This();

    node: *DeviceNode,
    ptr: c.drmModeFB2Ptr,
    handle: u32,

    pub fn init(node: *DeviceNode, ptr: c.drmModeFB2Ptr) Self {
      return .{
        .node = node,
        .ptr = ptr,
        .handle = ptr.*.fb_id,
      };
    }

    pub fn getPlane(self: Self, i: i4) Plane {
      return .{
        .handle = self.ptr.*.handles[i],
        .pitches = self.ptr.*.pitches[i],
        .offsets = self.ptr.*.offsets[i],
      };
    }

    pub fn getPlanes(self: Self) [4]Plane {
      return .{
        self.getPlane(0),
        self.getPlane(1),
        self.getPlane(2),
        self.getPlane(3),
      };
    }

    pub fn destroy(self: Self) void {
      // TODO: panic if this fails
      _ = c.drmModeRmFB(self.node.fd, self.ptr.*.fb_id);
      c.drmModeFreeFB2(self);
    }
  };
}

pub fn FrameBuffer(comptime S: type) type {
  if (@typeInfo(S) != .Int) @compileError("Size must be an integer");
  return struct {
    const Self = @This();

    node: *DeviceNode,
    ptr: c.drmModeFBPtr,
    handle: u32,

    pub fn init(node: *DeviceNode, ptr: c.drmModeFBPtr) Self {
      return .{
        .node = node,
        .ptr = ptr,
        .handle = ptr.*.fb_id,
      };
    }

    pub fn destroy(self: Self) void {
      // TODO: panic if this fails
      _ = c.drmModeRmFB(self.node.fd, self.ptr.*.fb_id);
      c.drmModeFreeFB(self);
    }
  };
}

pub fn AnyFrameBuffer(comptime S: type) type {
  return union {
    fb: FrameBuffer(S),
    fb2: FrameBuffer2(S),
    dumb: DumbFrameBuffer(S),
  };
}
