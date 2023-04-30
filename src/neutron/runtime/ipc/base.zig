const std = @import("std");
const Runtime = @import("../runtime.zig");

pub const Base = @import("base/base.zig");
pub const Client = @import("base/client.zig");
pub const Server = @import("base/server.zig");

/// Type of IPC instance
pub const Type = enum {
  client,
  server,
};

pub const Params = struct {
  @"type": Type,

  pub fn parseArgument(arg: []const u8) !Params {
    var params = Params {
      .type = .client,
    };

    var iter = std.mem.split(u8, arg, ",");
    while (iter.next()) |entry| {
      const sep_index = if (std.mem.indexOf(u8, entry, "=")) |value| value else continue;
      const key = entry[0..sep_index];
      const value = if (sep_index + 1 < entry.len) entry[(sep_index + 1)..] else continue;

      if (std.mem.eql(u8, key, "type")) {
        if (std.mem.eql(u8, value, "client")) params.type = .client
        else if (std.mem.eql(u8, value, "server")) params.type = .server
        else return error.InvalidType;
      } else {
        return error.InvalidKey;
      }
    }
    return params;
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.writeAll("type=");
    try writer.writeAll(switch (self.type) {
      .client => "client",
      .server => "server",
    });
  }
};

pub const Ipc = union(Type) {
  client: *Client,
  server: *Server,

  pub fn init(_: Params, runtime: *Runtime, allocator: ?std.mem.Allocator) !Ipc {
    _ = runtime;
    _ = allocator;
    @compileError("Not implemented!");
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

  pub fn toBase(self: *Ipc) *Base {
    return switch (self.*) {
      .client => |client| &client.base,
      .server => |server| &server.base,
    };
  }
};
