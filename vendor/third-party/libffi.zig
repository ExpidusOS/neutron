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
target_dir: []const u8,
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
  const lib = if (target.getObjectFormat() == .wasm)
    b.addStaticLibrary(.{
      .name = "ffi",
      .root_source_file = null,
      .version = version,
      .target = target,
      .optimize = optimize,
    })
  else
    b.addSharedLibrary(.{
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

  lib.addConfigHeader(b.addConfigHeader(.{
    .style = .{
      .autoconf = .{
        .path = getPath("/../fficonfig.h.in"),
      },
    },
    .include_path = "fficonfig.h",
  }, .{
    .EH_FRAME_FLAGS = "a",
    .FFI_NO_RAW_API = false,
    .FFI_MMAP_EXEC_EMUTRAMP_PAX = false,
    .FFI_EXEC_TRAMPOLINE_TABLE = target.isDarwin(),
    .FFI_MMAP_EXEC_WRIT = target.isDarwin() or target.isFreeBSD() or target.isOpenBSD(),
    .FFI_DEBUG = optimize == .Debug,
    .FFI_EXEC_STATIC_TRAMP = true,
    .FFI_NO_STRUCTS = false,
    .HAVE_AS_CFI_PSEUDO_OP = true,
    .HAVE_AS_REGISTER_PSEUDO_OP = target.getCpuArch() == .sparc,
    .HAVE_AS_S390_ZARCH = false,
    .HAVE_AS_SPARC_UA_PCREL = target.getCpuArch() == .sparc,
    .HAVE_AS_X86_64_UNWIND_SECTION_TYPE = target.getCpuArch() == .x86_64,
    .HAVE_AS_X86_PCREL = target.getCpuArch() == .x86 or target.getCpuArch() == .x86_64,
    .HAVE_ALLOCA_H = target.getAbi().isGnu(),
    .HAVE_DLFCN_H = true,
    .HAVE_INTTYPES_H = true,
    .HAVE_STDINT_H = true,
    .HAVE_STDIO_H = true,
    .HAVE_STDLIB_H = true,
    .HAVE_STRINGS_H = true,
    .HAVE_STRING_H = true,
    .HAVE_SYS_MEMFD_H = !target.isWindows(),
    .HAVE_SYS_STAT_H = !target.isWindows(),
    .HAVE_SYS_TYPES_H = !target.isWindows(),
    .HAVE_UNISTD_H = true,
    .HAVE_HIDDEN_VISIBILITY_ATTRIBUTE = true,
    .HAVE_PTRAUTH = false,
    .HAVE_LONG_DOUBLE = true,
    .HAVE_LONG_DOUBLE_VARIANT = false,
    .HAVE_RO_EH_FRAME = true,
    .HAVE_MEMFD_CREATE = true,
    .HAVE_MEMCPY = true,
    .SIZEOF_DOUBLE = @sizeOf(f64),
    .SIZEOF_LONG_DOUBLE = @sizeOf(c_longdouble),
    .SIZEOF_SIZE_T = @sizeOf(usize),
    .LIBFFI_GNU_SYMBOL_VERSIONING = true,
    .SYMBOL_UNDERSCORE = target.isDarwin(),
    .LT_OBJDIR = "",
    .PACKAGE = "libffi",
    .PACKAGE_BUGREPORT = "http://github.com/libffi/libffi/issues",
    .PACKAGE_NAME = "libffi",
    .PACKAGE_STRING = b.fmt("libffi {}.{}.{}", .{ version.major, version.minor, version.patch }),
    .PACKAGE_TARNAME = "libffi",
    .PACKAGE_URL = "",
    .PACKAGE_VERSION = b.fmt("{}.{}.{}", .{ version.major, version.minor, version.patch }),
    .STDC_HEADERS = true,
    .USING_PURIFY = false,
    .VERSION = b.fmt("{}.{}.{}", .{ version.major, version.minor, version.patch }),
  }));

  lib.linkLibC();
  lib.addIncludePath(getPath("/include"));
  lib.addIncludePath(dir);

  lib.addCSourceFiles(&[_][]const u8 {
    getPath("/src/closures.c"),
    getPath("/src/debug.c"),
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
    lib.addAssemblyFile(getPath("/src/x86/win64.S"));
    lib.addAssemblyFile(getPath("/src/x86/unix64.S"));
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
    .target_dir = target_dir,
    .lib = lib,
  };
}

pub fn link(self: Libffi, cs: *Build.CompileStep) void {
  cs.linkLibrary(self.lib);
  cs.addIncludePath(self.header_dir);
  cs.addIncludePath(self.target_dir);
}

pub fn install(self: Libffi) void {
  self.lib.install();
}
