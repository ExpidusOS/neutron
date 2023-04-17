const std = @import("std");
const base = @import("../base/device.zig");

pub const Gpu = @import("device/gpu.zig");

pub const Device = union(base.Type) {
  gpu: *Gpu,

  pub fn ref(self: *Device, allocator: ?std.mem.Allocator) !Device {
    return switch (self.*) {
      .gpu => |gpu| gpu.ref(allocator),
    };
  }

  pub fn unref(self: *Device) void {
    return switch (self.*) {
      .gpu => |gpu| gpu.unref(),
    };
  }

  pub fn toBase(self: *Device) *base.Base {
    return switch (self.*) {
      .gpu => |gpu| .{
        .gpu = &gpu.base,
      },
    };
  }
};
