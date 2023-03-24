const std = @import("std");
const builtin = @import("builtin");

pub const GpuDevice = @import("graphics/gpu-device.zig");

pub const platforms = @import("graphics/platforms.zig");

pub const platform = blk: {
  if (std.meta.trait.hasField(@tagName(builtin.os.tag))(platforms)) {
    break :blk @field(platforms, @tagName(builtin.os.tag));
  }
  break :blk platforms.dummy;
};
