const std = @import("std");

pub fn catchError(ret: c_int) anyerror!void {
  return switch (std.os.errno(ret)) {
    .SUCCESS => {
      if (ret < 0) {
        std.debug.panic("std.os.errno({}) returned success but errno is {}", .{ ret, ret });
      }
    },
    .NOMEM => std.mem.Allocator.Error.OutOfMemory,
    .INVAL => error.InvalidArgument,
    else => |err| std.os.unexpectedErrno(err),
  };
}
