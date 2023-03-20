const std = @import("std");
const Build = std.Build;
const Wayland = @import("wayland.zig");
const Wlroots = @This();

const version = std.builtin.Version {
  .major = 0,
  .minor = 16,
  .patch = 2,
};

builder: *Build,
config_header: *Build.ConfigHeaderStep,
version_header: *Build.ConfigHeaderStep,
lib: *Build.CompileStep,

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
  const lib = if (options.target.getObjectFormat() == .wasm)
    options.builder.addStaticLibrary(.{
      .name = "wlroots",
      .root_source_file = .{
        .path = getPath("/zig/zig-wlroots/src/wlroots.zig"),
      },
      .version = version,
      .target = options.target,
      .optimize = options.optimize,
    })
  else
    options.builder.addSharedLibrary(.{
      .name = "wlroots",
      .root_source_file = .{
        .path = getPath("/zig/zig-wlroots/src/wlroots.zig"),
      },
      .version = version,
      .target = options.target,
      .optimize = options.optimize,
    });

  lib.addIncludePath(getPath("/libs/wlroots/include"));

  const config_header = options.builder.addConfigHeader(.{
    .style = .blank,
    .include_path = "wlr/config.h",
  }, .{
    .WLR_HAS_DRM_BACKEND = 1,
    .WLR_HAS_LIBINPUT_BACKEND = 1,
    .WLR_HAS_X11_BACKEND = 1,
    .WLR_HAS_GLES2_RENDERER = 1,
    .WLR_HAS_VULKAN_RENDERER = 1,
    .WLR_HAS_GBM_ALLOCATOR = 1,
    .WLR_HAS_XWAYLAND = 1,
  });
  lib.addConfigHeader(config_header);

  const version_header = options.builder.addConfigHeader(.{
    .style = .blank,
    .include_path = "wlr/version.h",
  }, .{
    .WLR_VERSION_STR = options.builder.fmt("{}.{}.{}", .{ version.major, version.minor, version.patch }),
    .WLR_VERSION_MAJOR = version.major,
    .WLR_VERSION_MINOR = version.minor,
    .WLR_VERSION_MICRO = version.patch,
    .WLR_VERSION_NUM = ((version.major << 16) | (version.minor << 8) | version.patch),
  });
  lib.addConfigHeader(version_header);

  return .{
    .builder = options.builder,
    .config_header = config_header,
    .version_header = version_header,
    .lib = lib,
  };
}

pub fn createModule(self: Wlroots) *Build.Module {
  return self.builder.addModule("wlroots", .{
    .source_file = .{
      .path = getPath("/zig/zig-wlroots/src/wlroots.zig"),
    },
  });
}

pub fn install(self: Wlroots) void {
  self.lib.install();
}

pub fn link(self: Wlroots, cs: *Build.CompileStep) void {
  cs.linkLibrary(self.lib);
  cs.addIncludePath(getPath("/libs/wlroots/include"));
  cs.addConfigHeader(self.config_header);
  cs.addConfigHeader(self.version_header);
}
