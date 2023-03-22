const std = @import("std");
const builtin = @import("builtin");

pub const GpuDevice = @import("graphics/gpu-device.zig");

pub const platforms = @import("graphics/platforms.zig");

pub const platform = @field(platforms, @tagName(builtin.os.tag));
