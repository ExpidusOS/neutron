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
