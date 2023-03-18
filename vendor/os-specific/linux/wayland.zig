const std = @import("std");
const Build = std.Build;
const ScanProtocolsStep = @import("zig/zig-wayland/build.zig").ScanProtocolsStep;
const Expat = @import("../../expat.zig");
const Libffi = @import("../../libffi.zig");
const Wayland = @This();

const version = std.builtin.Version {
  .major = 1,
  .minor = 21,
  .patch = 0,
};

scanner: *ScanProtocolsStep,
module: *Build.Module,
scanner_exec: *Build.CompileStep,
libclient: *Build.CompileStep,
libserver: *Build.CompileStep,

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/libs/wayland" ++ suffix;
  };
}

fn getWaylandScanner(b: *Build) ![]const u8 {
  return std.mem.trim(u8, try b.exec(&[_][]const u8 {
    "pkg-config", "--variable=wayland_scanner", "wayland-scanner"
  }), &std.ascii.whitespace);
}

fn getDir(b: *Build) ![]const u8 {
  const subpath = [_][]const u8 {
    "neutron", "vendor", "os-specific", "linux", "wayland",
  };

  const path = try b.cache_root.join(b.allocator, &subpath);
  try b.cache_root.handle.makePath("neutron/vendor/os-specific/linux/wayland");
  return path;
}

pub const WaylandOptions = struct {
  libffi: *Libffi,
  builder: *Build,
  target: std.zig.CrossTarget,
  optimize: std.builtin.Mode
};

pub fn init(options: WaylandOptions) !Wayland {
  var host_target = std.zig.CrossTarget.fromTarget(options.builder.host.target);
  host_target.dynamic_linker = options.builder.host.dynamic_linker;

  const scanner_exec = options.builder.addExecutable(.{
    .name = "wayland-scanner",
    .root_source_file = null,
    .version = null,
    .target = host_target,
    .optimize = options.optimize,
  });

  scanner_exec.strip = true;

  initCS(options.builder, scanner_exec);
  Expat.init(options.builder, scanner_exec.target, scanner_exec.optimize).link(scanner_exec);

  scanner_exec.addCSourceFiles(&[_][]const u8 {
    getPath("/src/scanner.c"),
  }, &[_][]const u8{});

  const scanner = ScanProtocolsStep.create(.{
    .builder = options.builder,
    .exe = scanner_exec,
    .wayland_dir = getPath("/protocol"),
    .protocols_dir = getPath("/../wayland-protocols/")
  });
  scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

  scanner.generate("wl_compositor", 4);
  scanner.generate("wl_subcompositor", 1);
  scanner.generate("wl_shm", 1);
  scanner.generate("wl_output", 4);
  scanner.generate("wl_seat", 7);
  scanner.generate("wl_data_device_manager", 3);
  scanner.generate("xdg_wm_base", 2);

  const module = options.builder.addModule("wayland", .{
    .source_file = .{
      .generated = &scanner.result,
    }
  });

  const client = options.builder.addSharedLibrary(.{
    .name = "wayland-client",
    .root_source_file = .{
      .generated = &scanner.result
    },
    .version = version,
    .target = options.target,
    .optimize = options.optimize,
  });

  options.libffi.link(client);

  try initLib(options.builder, scanner, scanner_exec, client, false);

  client.addCSourceFiles(&[_][]const u8 {
    getPath("/src/wayland-client.c")
  }, &[_][]const u8{});

  const server = options.builder.addSharedLibrary(.{
    .name = "wayland-server",
    .root_source_file = .{
      .generated = &scanner.result
    },
    .version = version,
    .target = options.target,
    .optimize = options.optimize,
  });

  options.libffi.link(server);

  server.addCSourceFiles(&[_][]const u8 {
    getPath("/src/event-loop.c"),
    getPath("/src/wayland-shm.c"),
    getPath("/src/wayland-server.c")
  }, &[_][]const u8{});

  try initLib(options.builder, scanner, scanner_exec, server, true);

  return .{
    .scanner = scanner,
    .scanner_exec = scanner_exec,
    .module = module,
    .libclient = client,
    .libserver = server,
  };
}

fn initCS(b: *Build, cs: *Build.CompileStep) void {
  cs.linkLibC();

  cs.addConfigHeader(b.addConfigHeader(.{
    .style = .blank,
  }, .{}));

  cs.addIncludePath(getPath("/src"));

  cs.addConfigHeader(b.addConfigHeader(.{
    .style = .blank,
    .include_path = "wayland-version.h",
  }, .{
    .WAYLAND_VERSION_MAJOR = version.major,
    .WAYLAND_VERSION_MINIOR = version.minor,
    .WAYLAND_VERSION_MICRO = version.patch,
    .WAYLAND_VERSION = "1.21.0",
  }));

  cs.addCSourceFiles(&[_][]const u8 {
    getPath("/src/wayland-util.c"),
  }, &[_][]const u8{});
}

fn initLib(b: *Build, scanner: *ScanProtocolsStep, scanner_exec: *Build.CompileStep, lib: *Build.CompileStep, comptime server: bool) !void {
  initCS(b, lib);

  const dir = try getDir(b);

  const protocol = b.addRunArtifact(scanner_exec);
  protocol.addArgs(&[_][]const u8 {
     "-s", "public-code",
    getPath("/protocol/wayland.xml"),
  });

  lib.addCSourceFileSource(.{
    .source = protocol.addOutputFileArg("wayland-protocol.c"),
    .args = &[_][]const u8 {},
  });

  const core_header = b.addRunArtifact(scanner_exec);
  const core_header_out = Build.FileSource {
    .path = b.pathJoin(&[_][]const u8 {
      dir,
      (if (server) "wayland-server-protocol-core.h" else "wayland-client-protocol-core.h")
    })
  };

  core_header.addArgs(&[_][]const u8 {
    "-s", (if (server) "server-header" else "client-header"), "-c",
    getPath("/protocol/wayland.xml"),
    core_header_out.path
  });

  lib.addIncludePath(dir);

  const header = b.addRunArtifact(scanner_exec);

  const header_out = Build.FileSource {
    .path = b.pathJoin(&[_][]const u8 {
      dir,
      (if (server) "wayland-server-protocol.h" else "wayland-client-protocol.h")
    })
  };

  header.addArgs(&[_][]const u8 {
    "-s", (if (server) "server-header" else "client-header"),
    getPath("/protocol/wayland.xml"),
    header_out.path
  });

  lib.addCSourceFiles(&[_][]const u8 {
    getPath("/src/connection.c"),
    getPath("/../wayland-os.c"),
  }, &[_][]const u8{});

  scanner.step.dependOn(&scanner_exec.step);
  lib.step.dependOn(&scanner_exec.step);
  lib.step.dependOn(&scanner.step);

  lib.step.dependOn(&core_header.step);
  lib.step.dependOn(&header.step);
}
