pub const json = @import("./formatter/json.zig");
pub const xml = @import("./formatter/xml.zig");
pub const std = @import("std").fmt;

pub const FormatOptions = std.FormatOptions;

pub const Type = enum {
  json,
  xml,
  std,
};

pub fn format(t: Type, writer: anytype, comptime fmt: []const u8, args: anytype) !void {
  return switch (t) {
    .json => json.format(writer, fmt, args),
    .xml => xml.format(writer, fmt, args),
    .std => std.format(writer, fmt, args),
  };
}

pub fn formatType(t: Type, value: anytype, comptime fmt: []const u8, options: FormatOptions, writer: anytype, max_depth: usize) !void {
  return switch (t) {
    .json => json.formatType(value, fmt, options, writer, max_depth),
    .xml => xml.formatType(value, fmt, options, writer, max_depth),
    .std => std.formatType(value, fmt, options, writer, max_depth),
  };
}
