const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

fn path(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ suffix;
  };
}

pub fn build_lib(lib: *std.build.LibExeObjStep, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
  lib.setTarget(target);
  lib.setBuildMode(mode);
}

pub fn build(b: *Builder) void {
  const target = b.standardTargetOptions(.{});
  const mode = b.standardReleaseOptions();

  const is_wasm = target.getCpu().arch.isWasm();

  const is_runner = b.option(bool, "runner", "Enable the runner") orelse !is_wasm;
  const flutter_engine = b.option([]const u8, "flutter-engine", "Path to the Flutter Engine library") orelse null;

  if (!is_wasm) {
    if (flutter_engine == null) {
      std.debug.print("error: must set \"flutter-engine\" build option\n", .{});
      std.process.exit(1);
    }
  }

  const pkg = Pkg{
    .name = "neutron",
    .source = .{
      .path = "src/main.zig",
    }
  };

  const shared_lib = b.addSharedLibrary("neutron", pkg.source.path, b.version(0, 1, 0));
  shared_lib.install();
  build_lib(shared_lib, target, mode);

  const static_lib = b.addStaticLibrary("neutron", pkg.source.path);
  static_lib.install();
  build_lib(static_lib, target, mode);

  if (!is_wasm and is_runner) {
    const runner = b.addExecutable("neutron-runner", "src/main-runner.zig");
    runner.setTarget(target);
    runner.setBuildMode(mode);
    runner.addPackage(pkg);
    runner.linkLibrary(shared_lib);
    runner.install();

    b.default_step.dependOn(&runner.step);
  }

  b.default_step.dependOn(&shared_lib.step);
  b.default_step.dependOn(&static_lib.step);
}
