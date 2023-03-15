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
  use_wlroots: bool,
  docs: bool,
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
      .use_wlroots = target.isLinux(),
      .docs = true,
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
    const use_wlroots = b.option(bool, "use-wlroots", "Whether to enable the wlroots compositor") orelse options.use_wlroots;
    const docs = b.option(bool, "docs", "Whether to generate the documentation") orelse options.docs;

    options.build_runner = build_runner;
    options.flutter_engine = flutter_engine;
    options.use_wlroots = use_wlroots;
    options.docs = docs;
    return options;
  }
};

pub const Neutron = struct {
  options: NeutronOptions,
  config: *Build.OptionsStep,
  docs: ?*std.build.CompileStep,
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
      .docs = null,
      .shared_lib = null,
      .static_lib = null,
      .runner = null,
      .module = options.builder.addModule("neutron", .{
        .source_file = .{
          .path = getPath("/src/neutron.zig"),
        }
      }),
      .step = options.builder.step("build-neutron", "Build and install the Neutron Runtime & API"),
    };

    const is_wasm = options.target.getCpu().arch.isWasm();

    const version = std.builtin.Version{
      .major = 0,
      .minor = 1,
      .patch = 0,
    };

    config.addOption(?[]const u8, "flutter_engine", options.flutter_engine);
    config.addOption(bool, "use_wlroots", options.use_wlroots);
    config.addOption(std.builtin.Version, "version", version);

    for (try self.getDependencies(null)) |dep| {
      try self.module.dependencies.put(dep.name, dep.module);
    }

    if (!is_wasm) {
      if (options.flutter_engine == null) {
        std.debug.print("error: must set \"flutter-engine\" build option\n", .{});
        std.process.exit(1);
      }
    }

    if (options.docs) {
      self.docs = options.builder.addTest(.{
        .name = "neutron",
        .root_source_file = self.module.source_file,
        .target = options.target,
        .optimize = options.optimize,
      });

      self.docs.?.step.dependOn(&self.config.step);
      self.step.dependOn(&self.docs.?.step);

      for (try self.getDependencies(self.docs.?)) |dep| {
        self.docs.?.addModule(dep.name, dep.module);
      }

      self.docs.?.emit_docs = .{
        .emit_to = self.options.builder.pathJoin(&[_][]const u8 { self.options.builder.install_path, "docs" })
      };
    }

    if (options.shared_lib) {
      self.shared_lib = options.builder.addSharedLibrary(.{
        .name = "neutron",
        .root_source_file = self.module.source_file,
        .version = version,
        .target = options.target,
        .optimize = options.optimize,
      });

      self.makeCompileStep(self.shared_lib.?);

      for (try self.getDependencies(self.shared_lib.?)) |dep| {
        self.shared_lib.?.addModule(dep.name, dep.module);
      }
    }

    if (options.static_lib) {
      self.static_lib = options.builder.addStaticLibrary(.{
        .name = "neutron",
        .root_source_file = self.module.source_file,
        .target = options.target,
        .optimize = options.optimize,
      });

      self.makeCompileStep(self.static_lib.?);

      for (try self.getDependencies(self.static_lib.?)) |dep| {
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

  fn getDependencies(self: Neutron, comp: ?*std.build.CompileStep) ![]const Build.ModuleDependency {
    var len: u32 = 1;

    if (self.options.use_wlroots) {
      len += 1;
    }

    var deps = try self.options.builder.allocator.alloc(Build.ModuleDependency, len);

    var i: u32 = 0;
    deps[i] = .{
      .name = "neutron-config",
      .module = self.config.createModule(),
    };
    i += 1;

    if (self.options.use_wlroots) {
      const ScanProtocolsStep = @import("vendor/os-specific/linux/zig/zig-wayland/build.zig").ScanProtocolsStep;

      const scanner = ScanProtocolsStep.create(self.options.builder);
      scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

      deps[i] = .{
        .name = "wlroots",
        .module = self.options.builder.addModule("wlroots", .{
          .source_file = .{
            .path = getVendorPath("os-specific/linux/zig/zig-wlroots/src/wlroots.zig"),
          },
          .dependencies = &[_] Build.ModuleDependency{
            .{
              .name = "wayland",
              .module = self.options.builder.addModule("wayland", .{
                .source_file = .{
                  .generated = &scanner.result,
                },
              }),
            },
            .{
              .name = "xkbcommon",
              .module = self.options.builder.addModule("xkbcommon", .{
                .source_file = .{
                  .path = getVendorPath("os-specific/linux/zig/zig-wlroots/tinywl/deps/zig-xkbcommon/src/xkbcommon.zig"),
                },
              }),
            },
            .{
              .name = "pixman",
              .module = self.options.builder.addModule("pixman", .{
                .source_file = .{
                  .path = getVendorPath("os-specific/linux/zig/zig-wlroots/tinywl/deps/zig-pixman/pixman.zig"),
                },
              })
            },
          },
        }),
      };
      i += 1;

      if (comp != null) {
        comp.?.linkLibC();
        comp.?.linkSystemLibraryNeededPkgConfigOnly("wayland-server");
        comp.?.linkSystemLibraryNeededPkgConfigOnly("wlroots");
        comp.?.step.dependOn(&scanner.step);
        scanner.addCSource(comp.?);
      }
    }

    return deps;
  }

  fn makeCompileStep(self: Neutron, comp: *std.build.CompileStep) void {
    if (self.options.flutter_engine != null) {
      const is_wasm = comp.target.getCpu().arch.isWasm();

      comp.addIncludePath(self.options.flutter_engine.?);

      if (!is_wasm) {
        comp.addLibraryPath(self.options.flutter_engine.?);
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
