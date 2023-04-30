const builtin = @import("builtin");

pub const base = @import("hardware/base.zig");

pub usingnamespace switch (builtin.os.tag) {
  .linux => @import("hardware/linux.zig"),
  else => @compileError("OS is not supported at this time"),
};
