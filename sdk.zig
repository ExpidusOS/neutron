const std = @import("std");
const Build = std.Build;
const Self = @This();

const Flutter = @import("vendor/bindings/zig-flutter/sdk.zig");
const ScanProtocolsStep = @import("vendor/bindings/zig-wayland/build.zig").ScanProtocolsStep;
const xev = @import("vendor/third-party/zig/libxev/build.zig");

pub const version = std.builtin.Version {
  .major = 0,
  .minor = 1,
  .patch = 0,
};

pub const Options = struct {
  flutter: ?struct {
    global_cache: bool = false,
    gn_args: ?[][]const u8 = null,
  } = null,
  wayland: ?ScanProtocolsStep.Options = null,
};

builder: *Build,
config: *Build.OptionsStep,
target: std.zig.CrossTarget,
optimize: std.builtin.Mode,
options: Options,
flutter: *Flutter,
wl_scan_protocols: ?*ScanProtocolsStep,
docs: *Build.CompileStep,
artifacts: std.ArrayList(*Build.CompileStep),
step: Build.Step,

fn getPath(comptime suffix: []const []const u8) []const u8 {
  return comptime blk: {
    var dir = std.fs.path.dirname(@src().file) orelse ".";
    for (suffix) |value| dir = dir ++ std.fs.path.sep_str ++ value;
    break :blk dir;
  };
}

pub fn new(builder: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode, options: Options) !*Self {
  const self = builder.allocator.create(Self) catch @panic("OOM");
  self.* = .{
    .builder = builder,
    .config = builder.addOptions(),
    .options = options,
    .target = target,
    .optimize = optimize,
    .flutter = try Flutter.new(.{
      .builder = builder,
      .target = target,
      .optimize = optimize,
      .gn_args = if (options.flutter) |flutter| flutter.gn_args else null,
      .global_cache = if (options.flutter) |flutter| flutter.global_cache else false,
    }),
    .wl_scan_protocols = null,
    .docs = builder.addTest(.{
      .name = "neutron-docs",
      .root_source_file = .{
        .path = getPath(&.{
          "src", "neutron.zig",
        }),
      },
      .target = target,
      .optimize = optimize,
      .version = version,
    }),
    .artifacts = std.ArrayList(*Build.CompileStep).init(builder.allocator),
    .step = Build.Step.init(.{
      .id = .custom,
      .name = "Neutron",
      .owner = builder,
      .makeFn = make,
    }),
  };

  self.config.addOption(std.SemanticVersion, "version", self.getSemver());

  self.step.dependOn(&self.config.step);
  self.step.dependOn(&self.flutter.step);

  if (target.isLinux()) {
    const scanner = ScanProtocolsStep.create(builder, if (options.wayland) |value| value else ScanProtocolsStep.Options.auto(builder));
    self.wl_scan_protocols = scanner;
    self.step.dependOn(&self.wl_scan_protocols.?.step);
  }

  for (try self.getDependencies()) |dep| {
    self.docs.addModule(dep.name, dep.module);
  }

  self.docs.emit_docs = .{
    .emit_to = builder.pathJoin(&.{ builder.install_path, "doc" }),
  };
  self.linkLibraries(self.docs);
  return self;
}

fn make(step: *Build.Step, prog_node: *std.Progress.Node) !void {
  const self = @fieldParentPtr(Self, "step", step);

  if (self.target.getCpu().arch.isWasm()) return;

  for (self.artifacts.items) |artifact| {
    var sub_prog_node = prog_node.start(artifact.name, 1);
    defer sub_prog_node.end();

    artifact.addIncludePath(self.flutter.generated.getPath());
  }
}

fn getDependencies(self: *Self) ![]Build.ModuleDependency {
  var deps = std.ArrayList(Build.ModuleDependency).init(self.builder.allocator);

  try deps.appendSlice(&.{
    .{
      .name = "neutron-config",
      .module = self.config.createModule(),
    },
    .{
      .name = "s2s",
      .module = self.builder.addModule("s2s", .{
        .source_file = .{
          .path = getPath(&.{
            "vendor", "third-party", "zig", "s2s", "s2s.zig",
          }),
        },
      }),
    },
    .{
      .name = "xev",
      .module = xev.module(self.builder),
    },
  });

  if (self.wl_scan_protocols) |scanner| {
    try deps.append(.{
      .name = "wayland",
      .module = self.builder.addModule("wayland", .{
        .source_file = .{
          .generated = &scanner.result,
        },
      }),
    });
  }

  return deps.items;
}

pub fn createModule(self: *Self) !*Build.Module {
  return self.builder.addModule("neutron", .{
    .source_file = .{
      .path = getPath(&.{
        "src", "neutron.zig",
      }),
    },
    .dependencies = try self.getDependencies(),
  });
}

pub fn linkLibraries(self: *Self, artifact: *Build.CompileStep) void {
  artifact.linkLibC();

  if (self.wl_scan_protocols) |scanner| {
    scanner.addCSource(artifact);

    artifact.linkSystemLibrary("wayland-client");
    artifact.linkSystemLibrary("wayland-server");
  }

  artifact.step.dependOn(&self.step);
  artifact.addLibraryPathDirectorySource(.{
    .generated = &self.flutter.generated,
  });
 
  if (!self.target.getCpu().arch.isWasm()) {
    artifact.linkSystemLibraryNeeded("flutter_engine");
  }

  self.artifacts.append(artifact) catch @panic("OOM");
}

fn getBuild(self: *Self) ?[]const u8 {
  var build: ?[]const u8 = null;
  if (self.builder.findProgram(&.{}, &.{}) catch null) |git| {
    var out_code: u8 = 0;
    build = self.builder.execAllowFail(&.{
      git, "-C", getPath(&.{}), "rev-parse", "HEAD"
    }, &out_code, .Inherit) catch null;
  }
  return build;
}

pub fn getSemver(self: *Self) std.SemanticVersion {
  return .{
    .major = version.major,
    .minor = version.minor,
    .patch = version.patch,
    .pre = "prealpha",
    .build = self.getBuild(),
  };
}
