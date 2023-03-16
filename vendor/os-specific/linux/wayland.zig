const VendorEntry = @import("../../../vendor.zig").VendorEntry;
const std = @import("std");
const Build = std.Build;
const ScanProtocolsStep = @import("zig/zig-wayland/build.zig").ScanProtocolsStep;

const version = std.builtin.Version {
  .major = 1,
  .minor = 21,
  .patch = 0,
};

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/libs/wayland" ++ suffix;
  };
}

fn initScanner(b: *Build) *ScanProtocolsStep {
  const scanner = ScanProtocolsStep.create(b);
  scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

  scanner.generate("wl_compositor", 4);
  scanner.generate("wl_subcompositor", 1);
  scanner.generate("wl_shm", 1);
  scanner.generate("wl_output", 4);
  scanner.generate("wl_seat", 7);
  scanner.generate("wl_data_device_manager", 3);
  scanner.generate("xdg_wm_base", 2);
  return scanner;
}

fn init(lib: *Build.CompileStep) void {
  lib.addIncludePath(getPath("/src"));

  lib.addConfigHeader(lib.builder.addConfigHeader(.{
    .style = .blank,
    .include_path = "wayland-version.h",
  }, .{
    .WAYLAND_VERSION_MAJOR = version.major,
    .WAYLAND_VERSION_MINIOR = version.minor,
    .WAYLAND_VERSION_MICRO = version.patch,
    .WAYLAND_VERSION = "1.21.0",
  }));

  lib.addConfigHeader(lib.builder.addConfigHeader(.{
    .style = .blank,
  }, .{}));
}

pub fn initClient(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) VendorEntry {
  var scanner = initScanner(b);

  const lib = b.addSharedLibrary(.{
    .name = "wayland-client",
    .root_source_file = .{
      .generated = &scanner.result
    },
    .version = version,
    .target = target,
    .optimize = optimize,
  });
  init(lib);

  lib.linkLibC();
  lib.step.dependOn(&scanner.step);
  scanner.addCSource(lib);

  const module = b.addModule("wayland-client", .{
    .source_file = .{
      .generated = &scanner.result,
    }
  });

  return .{
    .lib = lib,
    .module = module,
  };
}

pub fn initServer(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) VendorEntry {
  var scanner = initScanner(b);

  const lib = b.addSharedLibrary(.{
    .name = "wayland-server",
    .root_source_file = .{
      .generated = &scanner.result
    },
    .version = version,
    .target = target,
    .optimize = optimize,
  });
  init(lib);

  lib.addCSourceFiles(&[_][]const u8 {
    getPath("/src/event-loop.c"),
    getPath("/src/wayland-shm.c"),
    getPath("/src/wayland-server.c")
  }, &[_][]const u8{});

  lib.linkLibC();
  lib.step.dependOn(&scanner.step);
  scanner.addCSource(lib);

  const module = b.addModule("wayland-server", .{
    .source_file = .{
      .generated = &scanner.result,
    }
  });

  return .{
    .lib = lib,
    .module = module,
  };
}
