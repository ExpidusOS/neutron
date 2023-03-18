const std = @import("std");
const Build = std.Build;
const Libffi = @This();

const version = std.builtin.Version {
  .major = 3,
  .minor = 4,
  .patch = 4,
};

const Error = error {
  InvalidArch,
  InvalidOs
};

const HeaderConfig = struct {
  TARGET: []const u8,
  HAVE_LONG_DOUBLE: []const u8,
  FFI_EXEC_TRAMPOLINE_TABLE: []const u8,
};

header_dir: []const u8,
lib: *Build.CompileStep,

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/libs/libffi" ++ suffix;
  };
}

fn getDir(b: *Build) ![]const u8 {
  const subpath = [_][]const u8 {
    "neutron", "vendor", "libffi",
  };

  const path = try b.cache_root.join(b.allocator, &subpath);
  try b.cache_root.handle.makePath("neutron/vendor/libffi");
  return path;
}

fn simpleCopy(source: []const u8, dest: []const u8) !void {
  const source_dir = std.fs.path.dirname(source);
  const dest_dir = std.fs.path.dirname(dest);

  std.debug.assert(source_dir != null);
  std.debug.assert(dest_dir != null);

  var source_dir_handle = try std.fs.openDirAbsolute(source_dir.?, .{});
  defer source_dir_handle.close();

  var dest_dir_handle = try std.fs.openDirAbsolute(dest_dir.?, .{});
  defer dest_dir_handle.close();

  try source_dir_handle.copyFile(source, dest_dir_handle, dest, .{});
}

pub fn init(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !Libffi {
  const lib = b.addSharedLibrary(.{
    .name = "ffi",
    .root_source_file = null,
    .version = version,
    .target = target,
    .optimize = optimize,
  });

  const dir = try getDir(b);
  const header_source = getPath("/include/ffi.h.in");

  var header_source_dir = try std.fs.openDirAbsolute(getPath("/include"), .{});
  defer header_source_dir.close();

  var header_dest_dir = try std.fs.openDirAbsolute(dir, .{});
  defer header_dest_dir.close();

  const header_source_size = (try header_source_dir.statFile("ffi.h.in")).size;
  var header_source_txt = try header_source_dir.readFileAlloc(b.allocator, header_source, header_source_size);
  defer b.allocator.free(header_source_txt);

  const header_config = HeaderConfig {
    .TARGET = try std.ascii.allocUpperString(b.allocator, @tagName(target.getCpuArch())),
    .HAVE_LONG_DOUBLE = "0", // TODO: use std.zig.CrossTarget to determine this
    .FFI_EXEC_TRAMPOLINE_TABLE = "0", // TODO: use std.zig.CrossTarget to determine this
  };
  defer b.allocator.free(header_config.TARGET);

  const header_fields = std.meta.fields(HeaderConfig);
  inline for (header_fields) |field| {
    const value = @field(header_config, field.name);
    header_source_txt = try std.mem.replaceOwned(u8, b.allocator, header_source_txt, "@" ++ field.name ++ "@", value);
  }

  try header_dest_dir.writeFile("ffi.h", header_source_txt);

  lib.linkLibC();
  lib.addIncludePath(getPath("/include"));
  lib.addIncludePath(getPath("/../ffi"));
  lib.addIncludePath(dir);

  lib.addCSourceFiles(&[_][]const u8 {
    getPath("/src/closures.c"),
    getPath("/src/dlmalloc.c"),
    getPath("/src/java_raw_api.c"),
    getPath("/src/prep_cif.c"),
    getPath("/src/raw_api.c"),
    getPath("/src/tramp.c"),
    getPath("/src/types.c"),
  }, &[_][]const u8 {
    "-Wno-int-conversion",
    "-Wno-incompatible-pointer-types",
    "-DGENERATE_LIBFFI_MAP=1",
    "-DHAVE_CONFIG_H=1",
    "-DFFI_BUILDING=1"
  });

  const target_dir = try switch (target.getCpuArch()) {
    .x86_64 => getPath("/src/x86"),
    .x86 => getPath("/src/x86"),
    .wasm32 => getPath("/src/wasm32"),
    else => Error.InvalidArch,
  };
  lib.addIncludePath(target_dir);

  if (target.getCpuArch() == .x86_64) {
    // FIXME: why is this emitting assembly, not llvm?
    const llvm_clang = b.addSystemCommand(&[_][]const u8 {
      "clang",
      "-fno-caret-diagnostics",
      "-target", try target.zigTriple(b.allocator),
      "-DGENERATE_LIBFFI_MAP=1",
      "-DHAVE_CONFIG_H=1",
      "-DFFI_BUILDING=1",
      "-DFFI_ASM=1",
      b.fmt("-I{s}", .{ getPath("/include") }),
      b.fmt("-I{s}", .{ getPath("/../ffi") }),
      b.fmt("-I{s}", .{ dir }),
      b.fmt("-I{s}", .{ target_dir }),
      "-c", "-emit-llvm",
    });

    const llvm_clang_path = if (target.getOsTag() == .windows) getPath("/src/x86/win64.S") else getPath("/src/x86/unix64.S");

    llvm_clang.addFileSourceArg(.{
      .path = llvm_clang_path,
    });

    llvm_clang.addArg("-o");
    const llvm_clang_out = llvm_clang.addOutputFileArg(b.fmt("{s}.bc", .{ std.fs.path.basename(llvm_clang_path) }));

    const clang_asm = b.addSystemCommand(&[_][]const u8 {
      "clang",
      "-fno-caret-diagnostics",
      "-target", try target.zigTriple(b.allocator),
      "-DGENERATE_LIBFFI_MAP=1",
      "-DHAVE_CONFIG_H=1",
      "-DFFI_BUILDING=1",
      "-DFFI_ASM=1",
      b.fmt("-I{s}", .{ getPath("/include") }),
      b.fmt("-I{s}", .{ getPath("/../ffi") }),
      b.fmt("-I{s}", .{ dir }),
      b.fmt("-I{s}", .{ target_dir }),
    });

    clang_asm.addFileSourceArg(llvm_clang_out);
    clang_asm.addArg("-o");
    const clang_asm_out = clang_asm.addOutputFileArg(b.fmt("{s}.o", .{ std.fs.path.basename(llvm_clang_path) }));

    clang_asm.step.dependOn(&llvm_clang.step);
    lib.step.dependOn(&clang_asm.step);
    lib.addObjectFileSource(clang_asm_out);
  }

  const target_src = switch (target.getCpuArch()) {
    .x86_64 => &[_][]const u8 {
      getPath("/src/x86/ffi64.c"),
      getPath("/src/x86/ffiw64.c")
    },
    .x86 => &[_][]const u8 {
      getPath("/src/x86/ffi.c")
    },
    .wasm32 => &[_][]const u8 {
      getPath("/src/wasm32/ffi.c")
    },
    else => Error.InvalidArch,
  };
  lib.addCSourceFiles(try target_src, &[_][]const u8 {});

  return .{
    .header_dir = dir,
    .lib = lib,
  };
}

pub fn link(self: Libffi, cs: *Build.CompileStep) void {
  cs.linkLibrary(self.lib);
  cs.addIncludePath(self.header_dir);
  // TODO: add headers
}

pub fn install(self: Libffi) void {
  self.lib.install();
}
