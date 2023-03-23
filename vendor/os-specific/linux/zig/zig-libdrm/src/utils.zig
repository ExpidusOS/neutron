const c = @import("c.zig").c;
const std = @import("std");

pub fn catchError(ret: c_int) anyerror!void {
  if (ret < 0) {
    return switch (@intToEnum(std.os.linux.E, -ret)) {
      .SUCCESS => {
        if (ret < 0) {
          std.debug.panic("std.os.linux.getErrno({}) returned success but errno is {}", .{ ret, ret });
        }
      },
      .ACCES => error.PermissionDenied,
      .NOENT => std.fs.File.OpenError.FileNotFound,
      .NOMEM => std.mem.Allocator.Error.OutOfMemory,
      .NOTTY => error.NoTTY,
      .INVAL => error.InvalidArgument,
      else => |err| std.os.unexpectedErrno(err),
    };
  }
}

pub fn catchErrno(ret: c_int) anyerror!void {
  if (ret < 0) {
    return catchError(c.__errno_location().*);
  }
}
