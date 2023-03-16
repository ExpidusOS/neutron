const Wayland = @import("vendor/os-specific/linux/wayland.zig");
const std = @import("std");

const Vendor = @This();

pub const VendorEntry = struct {
  lib: *std.Build.CompileStep,
  module: *std.Build.Module,
};

pub const VendorOptions = struct {
  use_wlroots: bool,
  flutter_engine: []const u8,
};

pub fn init(b: *std.Build, options: VendorOptions, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !std.StringHashMap(VendorEntry) {
  var map = std.StringHashMap(VendorEntry).init(b.allocator);

  if (options.use_wlroots) {
    try (&map).put("wayland-client", Wayland.initClient(b, target, optimize));
    try (&map).put("wayland-server", Wayland.initServer(b, target, optimize));
  }
  return map;
}
