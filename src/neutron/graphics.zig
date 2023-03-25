const std = @import("std");
const builtin = @import("builtin");

pub const GpuDevice = @import("graphics/gpu-device.zig");

pub const platforms = @import("graphics/platforms.zig");

pub const platform = blk: {
  if (std.meta.trait.hasDecls(platforms, &[_][]const u8 { @tagName(builtin.os.tag) })) {
    break :blk @field(platforms, @tagName(builtin.os.tag));
  }
  break :blk platforms.dummy;
};
