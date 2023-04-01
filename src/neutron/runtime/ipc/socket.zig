const std = @import("std");
const base = @import("base.zig");
const Runtime = @import("../runtime.zig");

pub const Base = @import("socket/base.zig");
pub const Client = @import("socket/client.zig");
pub const Server = @import("socket/server.zig");

pub const Params = struct {
  base: base.Params,
  path: ?[]const u8,
};

pub const Ipc = union(base.Type) {
  client: *Client,
  server: *Server,

  pub fn init(params: Params, runtime: *Runtime, allocator: ?std.mem.Allocator) !Ipc {
    return switch (params.base.type) {
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

  pub fn toBase(self: *Ipc) base.Ipc {
    return switch (self.*) {
      .client => |client| .{
        .client = &client.base
      },
      .server => |server| .{
        .server = &server.base,
      },
    };
  }
};
