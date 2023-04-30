const std = @import("std");
const Build = std.Build;
const Sdk = @import("sdk.zig");

pub fn build(b: *Build) !void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const sdk = try Sdk.new(b, target, optimize, .{});
  b.default_step.dependOn(&sdk.step);

  const docs_step = b.step("docs", "Generate & install documentation");
  docs_step.dependOn(&sdk.docs.step);

  const build_step = b.step("build", "Only build artifacts");

  const runner = b.addExecutable(.{
    .name = "neutron",
    .root_source_file = .{
      .path = "src/runner.zig",
    },
    .version = Sdk.version,
    .target = target,
    .optimize = optimize,
  });

  runner.addModule("neutron", try sdk.createModule());
  runner.addAnonymousModule("clap", .{
    .source_file = .{
      .path = "vendor/third-party/zig/zig-clap/clap.zig",
    },
  });
  sdk.linkLibraries(runner);

  build_step.dependOn(&runner.step);
  b.installArtifact(runner);
}
