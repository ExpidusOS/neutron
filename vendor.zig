const Expat = @import("vendor/third-party/expat.zig");
const Libffi = @import("vendor/third-party/libffi.zig");
const Drm = @import("vendor/os-specific/linux/drm.zig");
const Wayland = @import("vendor/os-specific/linux/wayland.zig");
const std = @import("std");
const Build = std.Build;

const Vendor = @This();

builder: *std.Build,
libffi: Libffi,
libdrm: ?*Drm,
wayland: ?Wayland,

pub const VendorOptions = struct {
  use_wayland: bool,
  flutter_engine: ?[]const u8,
};

pub fn init(b: *Build, options: VendorOptions, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !Vendor {
  var self = Vendor {
    .builder = b,
    .libffi = try Libffi.init(b, target, optimize),
    .libdrm = null,
    .wayland = null,
  };

  if (target.isLinux()) {
    self.libdrm = try Drm.init(.{
      .builder = b,
      .target = target,
      .optimize = optimize,
    });
  }

  if (options.use_wayland) {
    self.wayland = try Wayland.init(.{
      .libffi = &self.libffi,
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

  const arr = try self.builder.allocator.alloc(Build.ModuleDependency, len);

  var i: u32 = 0;

  if (self.wayland != null) {
    arr[i] = .{
      .name = "wayland",
      .module = self.wayland.?.createModule(),
    };
    i += 1;
  }
  return arr;
}
