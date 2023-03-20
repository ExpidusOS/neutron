const Expat = @import("vendor/expat.zig");
const Libffi = @import("vendor/libffi.zig");
const Wayland = @import("vendor/os-specific/linux/wayland.zig");
const Wlroots = @import("vendor/os-specific/linux/wlroots.zig");
const std = @import("std");
const Build = std.Build;

const Vendor = @This();

builder: *std.Build,
libffi: Libffi,
wayland: ?Wayland,
wlroots: ?Wlroots,

pub const VendorOptions = struct {
  use_wlroots: bool,
  flutter_engine: ?[]const u8,
};

pub fn init(b: *Build, options: VendorOptions, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !Vendor {
  var self = Vendor {
    .builder = b,
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

pub fn getDependencies(self: Vendor) ![]const Build.ModuleDependency {
  var len: u32 = 0;
  if (self.wayland != null) len += 1;
  if (self.wlroots != null) len += 1;

  const arr = try self.builder.allocator.alloc(Build.ModuleDependency, len);

  var i: u32 = 0;

  if (self.wayland != null) {
    arr[i] = .{
      .name = "wayland",
      .module = self.wayland.?.createModule(),
    };
    i += 1;
  }

  if (self.wlroots != null) {
    arr[i] = .{
      .name = "wlroots",
      .module = self.wlroots.?.createModule(),
    };
    i += 1;
  }
  return arr;
}
