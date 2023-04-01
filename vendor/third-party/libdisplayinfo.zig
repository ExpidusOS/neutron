const std = @import("std");
const Build = std.Build;
const DisplayInfo = @This();

const version = std.builtin.Version {
  .major = 0,
  .minor = 1,
  .patch = 1,
};

fn getPath(comptime suffix: []const u8) []const u8 {
  if (suffix[0] != '/') @compileError("path requires an absolute path!");
  return comptime blk: {
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    break :blk root_dir ++ "/libs/libdisplay-info" ++ suffix;
  };
}

fn gen_step_make(step: *Build.Step, prog_node: *std.Progress.Node) !void {
  _ = prog_node;
  const self = @fieldParentPtr(DisplayInfo, "gen_step", step);
  const b = step.owner;

  var man = b.cache.obtain();
  defer man.deinit();

  const input_file = try std.fs.openFileAbsolute(getPath("/../hwdata/pnp.ids"), .{});
  defer input_file.close();

  const input_reader = input_file.reader();
  const input = try input_reader.readAllAlloc(b.allocator, (try input_file.metadata()).size());
  defer b.allocator.free(input);

  var output = std.ArrayList(u8).init(b.allocator);
  defer output.deinit();

  try output.appendSlice(
    \\#include <string.h>
    \\#include <stdint.h>
    \\
    \\const char* pnp_id_table(const char* key);
    \\
    \\const char* pnp_id_table(const char* key) {
    \\  size_t len = strlen(key);
    \\  size_t i;
    \\  uint32_t u = 0;
    \\
    \\  if (len > 4)
    \\    return NULL;
    \\
    \\  for (i = 0; i < len; i++)
    \\    u = (u << 8) | (uint8_t)key[i];
    \\
    \\  switch (u) {
  );

  var iter = std.mem.split(u8, input, "\n");
  while (iter.next()) |line| {
    if (line.len < 5) continue;

    const id = line[0..3];
    const name = line[4..line.len];

    var u: u32 = 0;
    for (id) |c| u = (u << 8) | c;

    try std.fmt.format(output.writer(),
      \\    case {}: return "{s}";
      \\
    , .{ u, name });
  }

  // TODO: generate
  try output.appendSlice(
    \\    default: return NULL;
    \\  }
    \\}
  );

  man.hash.addBytes(output.items);

  if (try step.cacheHit(&man)) {
    const digest = man.final();
    const sub_path = try b.cache_root.join(b.allocator, &.{
      "o", &digest, "pnp-id-table.c",
    });

    self.gen_source.path = sub_path;
    return;
  }

  const digest = man.final();
  const sub_path = try std.fs.path.join(b.allocator, &.{ "o", &digest, "pnp-id-table.c" });
  const sub_path_dirname = std.fs.path.dirname(sub_path).?;

  b.cache_root.handle.makePath(sub_path_dirname) catch |err| {
    return step.fail("unable to make path '{}{s}': {s}", .{
      b.cache_root, sub_path_dirname, @errorName(err),
    });
  };

  b.cache_root.handle.writeFile(sub_path, output.items) catch |err| {
    return step.fail("unable to write file '{}{s}': {s}", .{
      b.cache_root, sub_path, @errorName(err),
    });
  };


  self.gen_source.path = try b.cache_root.join(b.allocator, &.{sub_path});
  try man.writeManifest();
}

builder: *Build,
gen_step: Build.Step,
gen_source: Build.GeneratedFile,
lib: *Build.CompileStep,

pub fn init(b: *Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !*DisplayInfo {
  const self = try b.allocator.create(DisplayInfo);
  self.* = .{
    .builder = b,
    .lib = if (target.getObjectFormat() == .wasm)
      b.addStaticLibrary(.{
        .name = "display-info",
        .root_source_file = null,
        .version = version,
        .target = target,
        .optimize = optimize,
      })
    else
      b.addSharedLibrary(.{
        .name = "display-info",
        .root_source_file = null,
        .version = version,
        .target = target,
        .optimize = optimize,
      }),
    .gen_step = Build.Step.init(.{
      .id = .custom,
      .name = "Generate pnp-id-table.c",
      .owner = b,
      .makeFn = gen_step_make,
    }),
    .gen_source = Build.GeneratedFile {
      .step = &self.gen_step,
    },
  };

  self.lib.addCSourceFileSource(.{
    .source = .{
      .generated = &self.gen_source,
    },
    .args = &[_][]const u8 {},
  });

  self.lib.step.dependOn(&self.gen_step);

  self.lib.linkLibC();
  self.lib.addIncludePath(getPath("/include"));

  self.lib.addCSourceFiles(&[_][]const u8 {
    getPath("/cta.c"),
    getPath("/cta-vic-table.c"),
    getPath("/cvt.c"),
    getPath("/displayid.c"),
    getPath("/dmt-table.c"),
    getPath("/edid.c"),
    getPath("/gtf.c"),
    getPath("/info.c"),
    getPath("/log.c"),
    getPath("/memory-stream.c"),
  }, &[_][]const u8 {});
  return self;
}

pub fn install(self: *DisplayInfo) void {
  self.lib.install();
}

pub fn link(self: *DisplayInfo, cs: *Build.CompileStep) void {
  cs.linkLibrary(self.lib);
}
