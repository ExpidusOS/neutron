const std = @import("std");

pub fn Color(comptime S: type) type {
  const type_info = @typeInfo(S);
  if (type_info != .Int) @compileError("Size must be an integer");

  return struct {
    const Self = @This();

    pub const bit_size = type_info.Int.bits;
    pub const full_size = bit_size * 3;

    red: S,
    green: S,
    blue: S,

    pub fn init() Self {
      return .{
        .red = 0,
        .green = 0,
        .blue = 0,
      };
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
      _ = fmt;
      _ = options;
      return std.fmt.format(writer, "{}, {}, {}", .{ self.red / bit_size, self.green / bit_size, self.blue / bit_size });
    }
  };
}

pub const U16Color = Color(u16);
