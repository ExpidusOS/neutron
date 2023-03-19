const Expat = @import("vendor/expat.zig");
const Libffi = @import("vendor/libffi.zig");
const Wayland = @import("vendor/os-specific/linux/wayland.zig");
const Wlroots = @import("vendor/os-specific/linux/wlroots.zig");
const std = @import("std");

const Vendor = @This();

libffi: Libffi,
wayland: ?Wayland,
wlroots: ?Wlroots,

pub const VendorOptions = struct {
  use_wlroots: bool,
  flutter_engine: []const u8,
};

pub fn init(b: *std.Build, options: VendorOptions, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !Vendor {
  var self = Vendor {
    .libffi = try Libffi.init(b, target, optimize),
    .wayland = null,
    .wlroots = null,
  };

  if (options.use_wlroots) {
    self.wayland = try Wayland.init(.{
      .libffi = &self.libffi,
      .builder = b,
      .target = target,
      .optimize = optimize,
    });

    self.wlroots = try Wlroots.init(.{
      .wayland = &self.wayland.?,
      .builder = b,
      .target = target,
      .optimize = optimize,
    });
  }
  return self;
}
