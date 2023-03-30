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
  .runtime_mode = clap.parsers.enumeration(neutron.runtime.Runtime.Mode),
  .ipc_mode = clap.parsers.enumeration(neutron.runtime.ipc.Type),
};

pub fn main() !void {
  const stdout = std.io.getStdOut().writer();
  const stderr = std.io.getStdErr().writer();

  const params = comptime clap.parseParamsComptime(
    \\-h, --help                Display this help and exit.
    \\-p, --path <str>          An optional parameter which sets the Flutter application base path.
    \\-m, --mode <runtime_mode> An optional parameter which sets the runtime mode (compositor, application).
    \\-i, --ipc-mode <ipc_mode> An optional parameter which sets the IPC mode (server, client).
    \\-s, --socket <str>        An optional parameter which sets the path to use for the IPC socket.
    \\-r, --runtime-dir <str>   An optional parameter set the runtime directory.
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

  const allocator = std.heap.page_allocator;
  var path = if (res.args.path == null) try std.fs.selfExeDirPathAlloc(allocator) else res.args.path.?;

  if (!std.fs.path.isAbsolute(path)) {
    path = try std.fs.path.relative(allocator, try std.process.getCwdAlloc(allocator), path);
    path = try std.fs.cwd().realpathAlloc(allocator, path);
  }

  const runtime_mode = if (res.args.mode) |mode| mode else .application;

  const runtime = try neutron.runtime.Runtime.new(.{
    .mode = runtime_mode,
    .ipc = .{
      .type = if (res.args.@"ipc-mode") |t| t else runtime_mode.getIpcType(),
      .socket = res.args.socket,
    },
  }, null, allocator);
  defer runtime.unref() catch @panic("Failed to unref");

  try stdout.print("{}\n", .{ runtime });
}
