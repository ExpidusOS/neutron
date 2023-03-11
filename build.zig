const std = @import("std");
const Build = std.Build;
const Pkg = std.build.Pkg;

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ suffix;
  };
}

fn getVendorPath(comptime suffix: []const u8) []const u8 {
  return comptime blk: {
    const root_dir = getPath("/vendor/");
    break :blk root_dir ++ suffix;
  };
}

pub const NeutronOptions = struct {
  builder: *Build,
  build_runner: bool,
  flutter_engine: ?[]const u8,

  static_lib: bool,
  shared_lib: bool,
  target: std.zig.CrossTarget,
  optimize: std.builtin.OptimizeMode,

  pub fn new(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) NeutronOptions {
    const is_wasm = target.getCpu().arch.isWasm();

    return .{
      .builder = b,
      .build_runner = !is_wasm,
      .flutter_engine = null,
      .static_lib = true,
      .shared_lib = true,
      .target = target,
      .optimize = optimize,
    };
  }

  pub fn new_auto(b: *Build) NeutronOptions {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    return NeutronOptions.new(b, target, optimize);
  }

  pub fn new_auto_with_options(b: *Build) NeutronOptions {
    var options = NeutronOptions.new_auto(b);

    const build_runner = b.option(bool, "runner", "Enable the runner for Neutron") orelse options.build_runner;
    const flutter_engine = b.option([]const u8, "flutter-engine", "Path to the Flutter Engine library") orelse options.flutter_engine;

    options.build_runner = build_runner;
    options.flutter_engine = flutter_engine;
    return options;
  }
};

pub const Neutron = struct {
  options: NeutronOptions,
  config: *Build.OptionsStep,
  config_module: *Build.Module,
  shared_lib: ?*std.build.CompileStep,
  static_lib: ?*std.build.CompileStep,
  runner: ?*std.build.CompileStep,
  module: *Build.Module,
  step: *Build.Step,

  pub fn new(options: NeutronOptions) !Neutron {
    const config = options.builder.addOptions();

    var self = Neutron{
      .options = options,
      .config = config,
      .config_module = config.createModule(),
      .shared_lib = null,
      .static_lib = null,
      .runner = null,
      .module = options.builder.addModule("neutron", .{
        .source_file = .{
          .path = getPath("/src/libs.zig"),
        }
      }),
      .step = options.builder.step("build-neutron", "Build and install the Neutron Runtime & API"),
    };

    const is_wasm = options.target.getCpu().arch.isWasm();

    const source = Build.FileSource{
      .path = getPath("/src/libs.zig"),
    };

    const version = std.builtin.Version{
      .major = 0,
      .minor = 1,
      .patch = 0,
    };

    config.addOption(?[]const u8, "flutter_engine", options.flutter_engine);
    config.addOption(std.builtin.Version, "version", version);

    for (self.getDependencies()) |dep| {
      try self.module.dependencies.put(dep.name, dep.module);
    }

    if (!is_wasm) {
      if (options.flutter_engine == null) {
        std.debug.print("error: must set \"flutter-engine\" build option\n", .{});
        std.process.exit(1);
      }
    }

    if (options.shared_lib) {
      self.shared_lib = options.builder.addSharedLibrary(.{
        .name = "neutron",
        .root_source_file = source,
        .version = version,
        .target = options.target,
        .optimize = options.optimize,
      });

      self.makeCompileStep(self.shared_lib.?);

      for (self.getDependencies()) |dep| {
        self.shared_lib.?.addModule(dep.name, dep.module);
      }
    }

    if (options.static_lib) {
      self.static_lib = options.builder.addStaticLibrary(.{
        .name = "neutron",
        .root_source_file = source,
        .target = options.target,
        .optimize = options.optimize,
      });

      self.makeCompileStep(self.static_lib.?);

      for (self.getDependencies()) |dep| {
        self.static_lib.?.addModule(dep.name, dep.module);
      }
    }

    if (options.build_runner) {
      self.runner = options.builder.addExecutable(.{
        .name = "neutron-runner",
        .root_source_file = .{
          .path = getPath("/src/runner.zig")
        },
        .version = version,
        .target = options.target,
        .optimize = options.optimize,
      });

      self.runner.?.addModule("neutron", self.module);

      if (options.shared_lib) {
        self.runner.?.linkLibrary(self.shared_lib.?);
      } else if (options.static_lib) {
        self.runner.?.linkLibrary(self.static_lib.?);
      }

      self.runner.?.addModule("clap", Neutron.makeModule(options.builder, "clap", "third-party/zig/zig-clap/clap.zig"));
      self.makeCompileStep(self.runner.?);
    }

    return self;
  }

  fn makeModule(b: *Build, name: []const u8, comptime path: []const u8) *Build.Module {
    return b.addModule(name, .{
      .source_file = .{
        .path = getVendorPath(path),
      },
    });
  }

  fn getDependencies(self: Neutron) []const Build.ModuleDependency {
    return &[_]Build.ModuleDependency {
      .{
        .name = "neutron-config",
        .module = self.config_module,
      }
    };
  }

  fn makeCompileStep(self: Neutron, comp: *std.build.CompileStep) void {
    if (self.options.flutter_engine != null) {
      const is_wasm = comp.target.getCpu().arch.isWasm();

      comp.addIncludePath(self.options.flutter_engine.?);

      if (!is_wasm) {
        comp.addLibraryPath(self.options.flutter_engine.?);
        comp.linkLibC();
        comp.linkSystemLibrary("flutter_engine");
      }
    }

    comp.install();
    comp.step.dependOn(&self.config.step);
    self.step.dependOn(&comp.step);
  }
};

pub fn build(b: *Build) !void {
  const neutron = try Neutron.new(NeutronOptions.new_auto_with_options(b));
  b.default_step.dependOn(neutron.step);
}
