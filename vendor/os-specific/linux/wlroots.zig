const std = @import("std");
const Build = std.Build;
const Wayland = @import("wayland.zig");
const Wlroots = @This();

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ suffix;
  };
}

pub const WlrootsOptions = struct {
  wayland: *Wayland,
  builder: *Build,
  target: std.zig.CrossTarget,
  optimize: std.builtin.Mode,
};

pub fn init(options: WlrootsOptions) !Wlroots {
  _ = options;
  return .{};
}
