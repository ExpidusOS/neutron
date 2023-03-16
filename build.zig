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
  lib: *Build.CompileStep,
  docs: ?*Build.CompileStep,
  step: *Build.Step,

  pub fn new(options: NeutronOptions) !Neutron {
    const b = options.builder;

    var self = Neutron {
      .options = options,
      .lib = b.addSharedLibrary(.{
        .name = "neutron",
        .root_source_file = .{
          .path = getPath("/src/neutron.zig"),
        },
        .version = .{
          .major = 0,
          .minor = 1,
          .patch = 0
        },
        .target = options.target,
        .optimize = options.optimize,
      }),
      .docs = null,
      .step = b.step("neutron", "Build and install all of Neutron"),
    };

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
    return self;
  }

  fn includeDependencies(self: Neutron, compile: *Build.CompileStep) !void {
    const vendor = try @import("vendor.zig").init(self.options.builder, .{
      .use_wlroots = self.options.use_wlroots,
      .flutter_engine = self.options.flutter_engine.?,
    }, self.options.target, self.options.optimize);

    compile.linkLibC();

    var it = vendor.iterator();
    while (it.next()) |item| {
      compile.linkLibrary(item.value_ptr.lib);
      compile.addModule(item.key_ptr.*, item.value_ptr.module);
      item.value_ptr.lib.install();
    }
  }
};

pub fn build(b: *Build) !void {
  const neutron = try Neutron.new(NeutronOptions.new_auto_with_options(b));
  b.default_step.dependOn(neutron.step);
}
