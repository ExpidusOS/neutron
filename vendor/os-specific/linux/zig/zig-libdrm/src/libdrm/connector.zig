const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const Crtc = @import("crtc.zig");
const DeviceNode = @import("device-node.zig");
const Encoder = @import("encoder.zig");
const Mode = @import("mode.zig");
const Connector = @This();

node: *const DeviceNode,
ptr: c.drmModeConnectorPtr,
type_name: [*:0]const u8,
type_id: u32,
id: u32,

pub fn init(node: *const DeviceNode, id: u32) !Connector {
  const ptr = c.drmModeGetConnector(node.fd, id);
  if (ptr == null) {
    return error.InputOutput;
  }

  const type_name = c.drmModeGetConnectorTypeName(ptr.*.connector_type);

  return .{
    .node = node,
    .ptr = ptr,
    .id = id,
    .type_name = if (type_name == null) "Unknown" else type_name,
    .type_id = ptr.*.connector_type_id,
  };
}

pub fn deinit(self: Connector) void {
  c.drmModeFreeConnector(self.ptr);
}

pub fn getPossibleCrtcs(self: Connector) ![]Crtc {
  std.debug.assert(self.ptr != null);

  const possible = c.drmModeConnectorGetPossibleCrtcs(self.node.fd, self.ptr);
  const res = c.drmModeGetResources(self.node.fd);
  if (res == null) {
    return error.InputOutput;
  }

  defer c.drmModeFreeResources(res);

  var count: usize = 0;
  for (res.*.crtcs[0..@intCast(usize, res.*.count_crtcs)], 0..) |_, i| {
    if ((possible & @as(u32, 1) << @intCast(u5, i)) == 1) {
      count += 1;
    }
  }

  const crtcs = try self.node.allocator.alloc(Crtc, count);
  var i: usize = 0;
  for (res.*.crtcs[0..@intCast(usize, res.*.count_crtcs)], 0..) |id, x| {
    if ((possible & @as(u32, 1) << @intCast(u5, x)) == 1) {
      crtcs[i] = try Crtc.init(self.node, id);
      i += 1;
    }
  }
  return crtcs;
}

pub fn getEncoder(self: Connector) !Encoder {
  std.debug.assert(self.ptr != null);
  return try Encoder.init(self.node, self.ptr.*.encoder_id);
}

pub fn getEncoders(self: Connector) ![]Encoder {
  std.debug.assert(self.ptr != null);

  if (self.ptr.*.encoders == null) {
    return error.InvalidMemory;
  }

  const encoders = try self.node.allocator.alloc(Encoder, @intCast(usize, self.ptr.*.count_encoders));
  for (encoders, self.ptr.*.encoders[0..@intCast(usize, self.ptr.*.count_encoders)]) |*v, id| {
    v.* = try Encoder.init(self.node, id);
  }
  return encoders;
}

pub fn getModes(self: Connector) ![]Mode {
  std.debug.assert(self.ptr != null);

  if (self.ptr.*.modes == null) {
    return error.InvalidMemory;
  }

  const modes = try self.node.allocator.alloc(Mode, @intCast(usize, self.ptr.*.count_modes));
  for (modes, self.ptr.*.modes[0..@intCast(usize, self.ptr.*.count_modes)]) |*v, mode| {
    v.* = Mode.init(@ptrCast(c.drmModeModeInfoPtr, @constCast(&mode)));
  }
  return modes;
}
