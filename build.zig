const std = @import("std");
const Build = std.Build;
const Pkg = std.build.Pkg;

const version = std.builtin.Version {
  .major = 0,
  .minor = 1,
  .patch = 0,
};

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
  lib: *Build.CompileStep,
  docs: ?*Build.CompileStep,
  runner: ?*Build.CompileStep,
  step: *Build.Step,

  pub fn new(options: NeutronOptions) !Neutron {
    const b = options.builder;

    var self = Neutron {
      .options = options,
      .config = b.addOptions(),
      .lib = b.addSharedLibrary(.{
        .name = "neutron",
        .root_source_file = .{
          .path = getPath("/src/neutron.zig"),
        },
        .version = version,
        .target = options.target,
        .optimize = options.optimize,
      }),
      .runner = null,
      .docs = null,
      .step = b.step("neutron", "Build and install all of Neutron"),
    };

    self.config.addOption(std.builtin.Version, "version", version);
    self.config.addOption(bool, "use_wlroots", self.options.use_wlroots);

    try self.includeDependencies(self.lib);
    self.lib.install();
    self.step.dependOn(&self.lib.step);

    if (self.options.docs) {
      const docs = b.addTest(.{
        .name = "neutron-docs",
        .root_source_file = self.lib.root_src.?,
        .version = self.lib.version,
        .target = options.target,
        .optimize = options.optimize,
      });

      try self.includeDependencies(docs);

      docs.emit_docs = .{
        .emit_to = b.pathJoin(&[_][]const u8 { b.install_path, "docs" })
      };

      self.docs = docs;
      self.step.dependOn(&docs.step);
    }

    if (self.options.build_runner) {
      const runner = b.addExecutable(.{
        .name = "neutron-runner",
        .root_source_file = .{
          .path = getPath("/src/runner.zig"),
        },
        .version = self.lib.version,
        .target = options.target,
        .optimize = options.optimize,
      });

      try self.includeDependencies(runner);

      runner.addAnonymousModule("clap", .{
        .source_file = .{
          .path = getPath("/vendor/third-party/zig/zig-clap/clap.zig"),
        },
      });

      runner.addModule("neutron", self.createModule());

      runner.install();
      self.runner = runner;
      self.step.dependOn(&runner.step);
    }
    return self;
  }

  pub fn createModule(self: Neutron) *Build.Module {
    return self.options.builder.addModule("neutron", .{
      .source_file = self.lib.root_src.?,
      .dependencies = &[_]Build.ModuleDependency {
        .{
          .name = "neutron-config",
          .module = self.config.createModule(),
        },
      }
    });
  }

  fn includeDependencies(self: Neutron, compile: *Build.CompileStep) !void {
    const vendor = try @import("vendor.zig").init(self.options.builder, .{
      .use_wlroots = self.options.use_wlroots,
      .flutter_engine = self.options.flutter_engine.?,
    }, self.options.target, self.options.optimize);

    compile.linkLibC();

    vendor.libffi.install();

    if (vendor.wayland != null) {
      compile.linkLibrary(vendor.wayland.?.libserver);
      compile.addModule("wayland", vendor.wayland.?.module);

      vendor.wayland.?.libserver.install();
    }
  }
};

pub fn build(b: *Build) !void {
  const host_dynamic_linker = b.option([]const u8, "host-dynamic-linker", "Set the dynamic linker for the host") orelse null;

  if (host_dynamic_linker != null) {
    b.host.dynamic_linker = std.zig.CrossTarget.DynamicLinker.init(host_dynamic_linker);
  }

  const neutron = try Neutron.new(NeutronOptions.new_auto_with_options(b));
  b.default_step.dependOn(neutron.step);
}
