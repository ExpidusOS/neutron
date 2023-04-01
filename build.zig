const std = @import("std");
const Build = std.Build;
const Pkg = std.build.Pkg;
const Vendor = @import("vendor.zig");

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

  use_wayland: bool,
  docs: bool,
  target: std.zig.CrossTarget,
  optimize: std.builtin.OptimizeMode,

  pub fn new(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) NeutronOptions {
    const is_wasm = target.getCpu().arch.isWasm();

    return .{
      .builder = b,
      .build_runner = !is_wasm,
      .flutter_engine = null,
      .use_wayland = target.isLinux(),
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
    const use_wayland = b.option(bool, "use-wayland", "Whether to enable the Wayland backend") orelse options.use_wayland;
    const docs = b.option(bool, "docs", "Whether to generate the documentation") orelse options.docs;
    const target_dynamic_linker = b.option([]const u8, "target-dynamic-linker", "Set the dynamic linker for the target") orelse null;

    if (target_dynamic_linker != null) {
      options.target.dynamic_linker = std.zig.CrossTarget.DynamicLinker.init(target_dynamic_linker);
    }

    options.build_runner = build_runner;
    options.flutter_engine = flutter_engine;
    options.use_wayland = use_wayland;
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
  vendor: Vendor,

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
      .vendor = try Vendor.init(b, .{
        .use_wayland = options.use_wayland,
        .flutter_engine = options.flutter_engine,
      }, options.target, options.optimize),
    };

    self.config.addOption(std.builtin.Version, "version", version);
    self.config.addOption(bool, "use_wayland", self.options.use_wayland);

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

      const deps = try self.getDependencies();
      defer b.allocator.free(deps);

      for (deps) |dep| {
        docs.addModule(dep.name, dep.module);
      }

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

      runner.addModule("neutron", try self.createModule());

      runner.install();
      self.runner = runner;
      self.step.dependOn(&runner.step);
    }
    return self;
  }

  pub fn getDependencies(self: Neutron) ![]const Build.ModuleDependency {
    const from_vendor = try self.vendor.getDependencies();
    defer self.options.builder.allocator.free(from_vendor);

    const to_add = &[_]Build.ModuleDependency {
      .{
        .name = "neutron-config",
        .module = self.config.createModule(),
      },
    };

    const len = from_vendor.len + to_add.len;
    const val = try self.options.builder.allocator.alloc(Build.ModuleDependency, len);

    var i: u32 = 0;
    for (from_vendor) |item| {
      val[i] = item;
      i += 1;
    }
    for (to_add) |item| {
      val[i] = item;
      i += 1;
    }

    return val;
  }

  pub fn createModule(self: Neutron) !*Build.Module {
    return self.options.builder.addModule("neutron", .{
      .source_file = self.lib.root_src.?,
      .dependencies = try self.getDependencies()
    });
  }

  fn includeDependencies(self: Neutron, compile: *Build.CompileStep) !void {
    compile.linkLibC();

    self.vendor.libdisplayinfo.link(compile);
    self.vendor.libdisplayinfo.install();

    if (self.vendor.libffi != null) {
      self.vendor.libffi.?.install();
    }

    if (self.vendor.wayland != null) {
      self.vendor.wayland.?.link(compile);
      self.vendor.wayland.?.install();
    }

    if (self.vendor.libdrm != null) {
      self.vendor.libdrm.?.link(compile);
      self.vendor.libdrm.?.install();
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
