const std = @import("std");
const base = @import("base.zig");
const Runtime = @import("../runtime.zig");

pub const Base = @import("socket/base.zig");
pub const Client = @import("socket/client.zig");
pub const Server = @import("socket/server.zig");

pub const Params = struct {
  base: base.Params,
  path: ?[]const u8,

  pub fn init() Params {
    return .{
      .base = .{
        .type = .client,
      },
      .path = null,
    };
  }

  pub fn parseArgument(arg: []const u8) !Params {
    var params = Params {
      .base = .{
        .type = .client,
      },
      .path = null,
    };

    var iter = std.mem.split(u8, arg, ",");
    var index: usize = 0;
    while (iter.next()) |entry| {
      const sep_index = if (std.mem.indexOf(u8, entry, "=")) |value| value else continue;
      const key = entry[0..sep_index];
      const value = if (sep_index + 1 < entry.len) entry[(sep_index + 1)..] else continue;

      if (std.mem.eql(u8, key, "path")) {
        if (params.path != null) return error.DuplicateKey;
        params.path = value;
      } else {
        params.base = try base.Params.parseArgument(arg[index..]);
      }

      index += entry.len + 1;
    }
    return params;
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    if (self.path) |path| {
      try writer.writeAll("path=");
      try writer.writeAll(path);
      try writer.writeAll(",");
    }

    try self.base.format(fmt, options, writer);
  }
};

fn findActive(allocator: std.mem.Allocator, runtime: *Runtime) ![]const u8 {
  var dir = try std.fs.openIterableDirAbsolute(runtime.dir, .{
    .access_sub_paths = false,
    .no_follow = true,
  });
  defer dir.close();

  var iter = dir.iterate();
  while (try iter.next()) |entry| {
    if (std.mem.startsWith(u8, entry.name, "neutron-") and std.mem.endsWith(u8, entry.name, ".sock")) {
      return std.fs.path.join(allocator, &[_][]const u8 {
        runtime.dir,
        entry.name,
      });
    }
  }

  return error.FileNotFound;
}

fn findNew(allocator: std.mem.Allocator, runtime: *Runtime) ![]const u8 {
  var i: usize = 0;
  while (i < @typeInfo(usize).Int.bits) : (i += 1) {
    const fmt = try std.fmt.allocPrint(allocator, "neutron-{}.sock", .{ i });
    defer allocator.free(fmt);

    const path = try std.fs.path.join(allocator, &[_][]const u8 {
      runtime.dir,
      fmt,
    });
    defer allocator.free(path);

    std.fs.accessAbsolute(path, .{}) catch return allocator.dupe(u8, path);
  }
  return error.FileNotFound;
}

pub const Ipc = union(base.Type) {
  client: *Client,
  server: *Server,

  pub fn init(params: Params, runtime: *Runtime, allocator: ?std.mem.Allocator) !Ipc {
    const alloc = if (allocator) |value| value else runtime.type.allocator;
    return switch (params.base.type) {
      .client => .{
        .client = try Client.new(.{
          .runtime = runtime,
          .address = try std.net.Address.initUnix(if (params.path) |value| try alloc.dupe(u8, value) else try findActive(alloc, runtime)),
        }, null, alloc)
      },
      .server => .{
        .server = try Server.new(.{
          .runtime = runtime,
          .address = try std.net.Address.initUnix(if (params.path) |value| try alloc.dupe(u8, value) else try findNew(alloc, runtime)),
        }, null, alloc),
      },
    };
  }

  pub fn ref(self: *Ipc, allocator: ?std.mem.Allocator) !Ipc {
    return switch (self.*) {
      .client => |client| .{
        .client = try client.ref(allocator),
      },
      .server => |server| .{
        .server = try server.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Ipc) void {
    return switch (self.*) {
      .client => |client| client.unref(),
      .server => |server| server.unref()
    };
  }

  pub fn toBase(self: *Ipc) base.Ipc {
    return switch (self.*) {
      .client => |client| .{
        .client = &client.base_client
      },
      .server => |server| .{
        .server = &server.base_server,
      },
    };
  }
};
