const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const DeviceNode = @import("device-node.zig");
const Connector = @This();

node: *const DeviceNode,
ptr: c.drmModeConnectorPtr,
id: u32,

pub fn init(node: *const DeviceNode, id: u32) !Connector {
  return .{
    .node = node,
    .ptr = c.drmModeGetConnector(node.fd, id),
    .id = id,
  };
}

pub fn deinit(self: Connector) void {
  c.drmModeFreeConnector(self.ptr);
}
