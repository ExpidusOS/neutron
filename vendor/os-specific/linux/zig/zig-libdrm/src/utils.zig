const std = @import("std");

pub fn wrapErrno(ret: c_int) anyerror {
  return switch (std.os.errno(ret)) {
    .NOMEM => std.mem.Allocator.Error.OutOfMemory,
    else => |err| std.os.unexpectedErrno(err),
  };
}
