const std = @import("std");

pub fn catchError(ret: c_int) anyerror!void {
  if (ret < 0) {
    return switch (@intToEnum(std.os.linux.E, -ret)) {
      .SUCCESS => {
        if (ret < 0) {
          std.debug.panic("std.os.linux.getErrno({}) returned success but errno is {}", .{ ret, ret });
        }
      },
      .NOENT => std.fs.File.OpenError.FileNotFound,
      .NOMEM => std.mem.Allocator.Error.OutOfMemory,
      .INVAL => error.InvalidArgument,
      else => |err| std.os.unexpectedErrno(err),
    };
  }
}
