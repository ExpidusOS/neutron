const std = @import("std");
const Runtime = @import("runtime.zig");

pub const Base = @import("ipc/base.zig");
pub const Client = @import("ipc/client.zig");
pub const Server = @import("ipc/server.zig");

/// Type of IPC instance
pub const Type = enum {
  client,
  server,
};

/// IPC instance
pub const Ipc = union(Type) {
  pub const Params = struct {
    @"type": Type,
    socket: ?[]const u8,
  };

  client: *Client,
  server: *Server,

  pub fn init(params: Params, runtime: *Runtime, allocator: ?std.mem.Allocator) !Ipc {
    return switch (params.type) {
      .client => .{
        .client = try Client.new(.{
          .runtime = runtime,
        }, null, allocator)
      },
      .server => .{
        .server = try Server.new(.{
          .runtime = runtime,
        }, null, allocator),
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

  pub fn unref(self: *Ipc) !void {
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
