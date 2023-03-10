const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub fn buildLib(lib: *std.build.LibExeObjStep, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
  lib.setTarget(target);
  lib.setBuildMode(mode);
}

pub fn build(b: *Builder) void {
  const flutter_engine = b.option([]const u8, "flutter-engine", "Path to the Flutter Engine library") orelse null;
  if (flutter_engine == null) {
    std.debug.print("error: must set \"flutter-engine\" build option\n", .{});
    std.process.exit(1);
  }

  const target = b.standardTargetOptions(.{});
  const mode = b.standardReleaseOptions();

  const sharedLib = b.addSharedLibrary("neutron", "src/main.zig", b.version(0, 1, 0));
  sharedLib.install();
  buildLib(sharedLib, target, mode);

  const staticLib = b.addStaticLibrary("neutron", "src/main.zig");
  staticLib.install();
  buildLib(staticLib, target, mode);

  b.default_step.dependOn(&sharedLib.step);
  b.default_step.dependOn(&staticLib.step);
}
