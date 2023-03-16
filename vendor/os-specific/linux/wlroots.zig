const VendorEntry = @import("../../../vendor.zig").VendorEntry;
const std = @import("std");
const Build = std.Build;

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ suffix;
  };
}

pub fn init(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) VendorEntry {
  const lib = b.addSharedLibrary(.{
  });
}
