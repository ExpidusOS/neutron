const std = @import("std");

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/zig/s2s" ++ suffix;
  };
}

pub fn createModule(b: *std.Build) *std.Build.Module {
  return b.addModule("s2s", .{
    .source_file = .{
      .path = getPath("/s2s.zig"),
    },
    .dependencies = &.{},
  });
}
