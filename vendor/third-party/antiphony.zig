const std = @import("std");

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/zig/antiphony" ++ suffix;
  };
}

pub fn createModule(b: *std.Build) *std.Build.Module {
  return b.addModule("antiphony", .{
    .source_file = .{
      .path = getPath("/src/antiphony.zig"),
    },
    .dependencies = &.{
      .{
        .name = "s2s",
        .module = b.addModule("s2s", .{
          .source_file = .{
            .path = getPath("/vendor/s2s/s2s.zig"),
          },
        }),
      },
    },
  });
}
