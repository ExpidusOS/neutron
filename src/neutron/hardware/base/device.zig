const std = @import("std");

pub const Base = @import("device/base.zig");
pub const Gpu = @import("device/gpu.zig");

pub const Type = enum {
  gpu,
};

pub const Device = union(Type) {
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

  pub fn toBase(self: *Device) *Base {
    return switch (self.*) {
      .gpu => |gpu| &gpu.base,
    };
  }
};
