const std = @import("std");

pub fn format(writer: anytype, comptime fmt: []const u8, args: anytype) !void {
  _ = writer;
  _ = fmt;
  _ = args;
}

pub fn formatType(value: anytype, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype, max_depth: usize) @TypeOf(writer).Error!void {
  _ = value;
  _ = fmt;
  _ = options;
  _ = max_depth;
}
