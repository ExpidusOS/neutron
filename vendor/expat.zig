const std = @import("std");
const Build = std.Build;
const Expat = @This();

const version = std.builtin.Version {
  .major = 2,
  .minor = 5,
  .patch = 0,
};

lib: *Build.CompileStep,

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/libs/expat/expat" ++ suffix;
  };
}

pub fn init(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) Expat {
  const lib = b.addSharedLibrary(.{
    .name = "expat",
    .root_source_file = null,
    .version = version,
    .target = target,
    .optimize = optimize,
  });

  lib.linkLibC();

  lib.addIncludePath(getPath("/lib"));

  lib.addConfigHeader(lib.builder.addConfigHeader(.{
    .style = .blank,
    .include_path = "expat_config.h",
  }, .{
    .HAVE_GETRANDOM = true,
  }));

  lib.addCSourceFiles(&[_][]const u8 {
    getPath("/lib/xmlparse.c"),
    getPath("/lib/xmlrole.c"),
    getPath("/lib/xmltok.c"),
    getPath("/lib/xmltok_impl.c"),
    getPath("/lib/xmltok_ns.c"),
  }, &[_][]const u8 {});

  return .{
    .lib = lib,
  };
}

pub fn link(self: Expat, cs: *Build.CompileStep) void {
  cs.linkLibrary(self.lib);
  cs.addIncludePath(getPath("/lib"));
}
