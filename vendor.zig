const Expat = @import("vendor/expat.zig");
const Wayland = @import("vendor/os-specific/linux/wayland.zig");
const std = @import("std");

const Vendor = @This();

wayland: ?Wayland,

pub const VendorOptions = struct {
  use_wlroots: bool,
  flutter_engine: []const u8,
};

pub fn init(b: *std.Build, options: VendorOptions, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !Vendor {
  var self = Vendor {
    .wayland = null,
  };

  if (options.use_wlroots) {
    self.wayland = try Wayland.init(.{
      .builder = b,
      .target = target,
      .optimize = optimize,
    });
  }
  return self;
}
