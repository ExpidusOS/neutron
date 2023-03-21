pub const config = @import("neutron-config");

pub const displaykit = @import("neutron/displaykit.zig");
pub const elemental = @import("neutron/elemental.zig");

const std = @import("std");
const libdrm = @import("libdrm");

pub fn drmTest(allocator: std.mem.Allocator) !void {
  var devices = try libdrm.getDevices2Alloc(allocator, 0);
  defer libdrm.freeDevices(allocator, devices);

  std.debug.print("{any}\n", .{ devices });

  for (devices) |device| {
    var nodes = try device.getNodes();
    for (nodes, 0..) |node, i| {
      if (node == null) {
        std.debug.print("#{}: N/A\n", .{ i });
        continue;
      }

      defer node.?.deinit();

      std.debug.print("#{}: {}\n", .{ i, node.? });
    }
  }
}
