const builtin = @import("builtin");
const std = @import("std");
const clap = @import("clap");
const neutron = @import("neutron");

const parser = .{
  .string = clap.parsers.string,
  .str = clap.parsers.string,
  .u8 = clap.parsers.int(u8, 0),
  .u16 = clap.parsers.int(u16, 0),
  .u32 = clap.parsers.int(u32, 0),
  .u64 = clap.parsers.int(u64, 0),
  .usize = clap.parsers.int(usize, 0),
  .i8 = clap.parsers.int(i8, 0),
  .i16 = clap.parsers.int(i16, 0),
  .i32 = clap.parsers.int(i32, 0),
  .i64 = clap.parsers.int(i64, 0),
  .isize = clap.parsers.int(isize, 0),
  .f32 = clap.parsers.float(f32),
  .f64 = clap.parsers.float(f64),
  .mode = clap.parsers.enumeration(neutron.runtime.Runtime.Mode),
};

pub fn main() !void {
  const stdout = std.io.getStdOut().writer();
  const stderr = std.io.getStdErr().writer();

  const params = comptime clap.parseParamsComptime(
    \\-h, --help              Display this help and exit.
    \\-p, --path <str>        An optional parameter which sets the Flutter application base path.
    \\-m, --mode <mode>       An optional parameter which sets the runtime mode.
    \\-r, --runtime-dir <str> An optional parameter set the runtime directory.
    \\
  );

  var diag = clap.Diagnostic{};
  var res = clap.parse(clap.Help, &params, parser, .{
    .diagnostic = &diag
  }) catch |err| {
    diag.report(stderr, err) catch {};
    return err;
  };

  defer res.deinit();

  if (res.args.help) {
    try stdout.print(
      \\Flutter Runner for Neutron (v{}) - API & Runtime for ExpidusOS
      \\
      \\Options:
      \\
    , .{
      neutron.config.version
    });
    return clap.help(stdout, clap.Help, &params, .{});
  }

  const mode = res.args.mode orelse neutron.runtime.Runtime.Mode.application;

  if (mode == .compositor) {
    if (builtin.os.tag != .linux) {
      try stderr.print("Neutron runner cannot execute in compositor mode outside of Linux.\n", .{});
      std.process.exit(1);
    }
  }

  const allocator = std.heap.page_allocator;
  var path = if (res.args.path == null) try std.fs.selfExeDirPathAlloc(allocator) else res.args.path.?;

  if (!std.fs.path.isAbsolute(path)) {
    path = try std.fs.path.relative(allocator, try std.process.getCwdAlloc(allocator), path);
    path = try std.fs.cwd().realpathAlloc(allocator, path);
  }

  const runtime = try neutron.runtime.Runtime.new(.{
    .mode = mode,
    .path = path,
    .runtime_dir = res.args.@"runtime-dir"
  }, allocator);
  defer runtime.unref();

  try neutron.elemental.formatter.json(runtime, "", .{}, stdout);
}
