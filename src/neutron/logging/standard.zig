const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../elemental.zig");
const Logger = @import("base.zig");
const Self = @This();

const vtable = Logger.VTable {
  .write = (struct {
    fn callback(_base: *anyopaque, msg: Logger.LogMessage) !void {
      const base = Logger.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      const file = self.getFileForLevel(msg.level);
      const tty = std.debug.detectTTYConfig(file);
      const writer = file.writer();

      try tty.setColor(writer, .Reset);
      try tty.setColor(writer, .Dim);
      try writer.writeByte('[');

      try tty.setColor(writer, .Bold);
      try writer.writeAll(msg.file);

      try tty.setColor(writer, .Reset);
      try tty.setColor(writer, .Dim);
      try writer.print(":{}", .{ msg.timestamp });

      try tty.setColor(writer, .Reset);
      try tty.setColor(writer, .Dim);
      try writer.writeByte(':');

      try tty.setColor(writer, .Reset);
      try tty.setColor(writer, self.getColorForLevel(msg.level));
      try writer.writeAll(switch (msg.level) {
        .err => "error",
        .warn => "warning",
        .info => "info",
        .debug => "debug",
      });

      try tty.setColor(writer, .Reset);
      try tty.setColor(writer, .Dim);
      try writer.writeAll("] ");

      try tty.setColor(writer, .Reset);
      try tty.setColor(writer, .White);
      try tty.setColor(writer, .Bold);
      try writer.writeAll(msg.message);
      try writer.writeByte('\n');
      try tty.setColor(writer, .Reset);
    }
  }).callback,
};

pub const Params = struct {
  out: ?std.fs.File = null,
  err: ?std.fs.File = null,

  pub fn init() Params {
    return .{};
  }

  pub fn parseArgument(arg: []const u8) !Params {
    var params = Params.init();
    const allocator = std.heap.page_allocator;

    var iter = std.mem.split(u8, arg, ",");
    var index: usize = 0;
    while (iter.next()) |entry| {
      const sep_index = if (std.mem.indexOf(u8, entry, "=")) |value| value else continue;
      const key = entry[0..sep_index];
      const value = if (sep_index + 1 < entry.len) entry[(sep_index + 1)..] else continue;

      if (std.mem.eql(u8, key, "out") or std.mem.eql(u8, key, "err")) {
        var path = try allocator.dupe(u8, value);

        if (!std.fs.path.isAbsolute(path)) {
          path = try std.fs.path.relative(allocator, try std.process.getCwdAlloc(allocator), path);
          path = try std.fs.cwd().realpathAlloc(allocator, path);
        }
        defer allocator.free(path);

        const file = try std.fs.openFileAbsolute(path, .{
          .mode = .write_only,
        });

        if (std.mem.eql(u8, key, "out")) params.out = file
        else params.err = file;
      } else {
        return error.InvalidArgument;
      }

      index += entry.len + 1;
    }
    return params;
  }

  fn formatFile(file: std.fs.File, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
    var buff = [_]u8 {0} ** std.fs.MAX_PATH_BYTES;
    _ = std.os.getFdPath(file.handle, &buff) catch return;
    return std.fmt.formatType(&buff, fmt, options, writer, 1);
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
    try writer.writeAll("out=");
    try formatFile(if (self.out) |out| out else std.io.getStdOut(), fmt, options, writer);

    try writer.writeAll(",err=");
    try formatFile(if (self.err) |err| err else std.io.getStdErr(), fmt, options, writer);
  }
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = undefined,
      .out = if (params.out) |out| out else std.io.getStdOut(),
      .err = if (params.err) |err| err else std.io.getStdErr(),
    };

    _ = try Logger.init(&self.base, .{
      .vtable = &vtable,
    }, self, t.allocator);

    try self.base.fmtDebug("Standard logger initialized with \"{s}\"", .{ params });
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = undefined,
    };

    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }

  pub fn destroy(self: *Self) void {
    self.out.close();
    self.err.close();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Logger,
out: std.fs.File,
err: std.fs.File,

pub usingnamespace Type.Impl;

pub fn getFileForLevel(self: *Self, level: std.log.Level) std.fs.File {
  return switch (level) {
    .err => self.err,
    .warn => self.err,
    .info => self.out,
    .debug => self.out,
  };
}

pub fn getColorForLevel(self: *Self, level: std.log.Level) std.debug.TTY.Color {
  _ = self;
  return switch (level) {
    .err => .Red,
    .warn => .Yellow,
    .info => .Green,
    .debug => .Cyan,
  };
}
