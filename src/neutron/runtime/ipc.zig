const std = @import("std");
const Runtime = @import("runtime.zig");

pub const base = @import("ipc/base.zig");
pub const socket = @import("ipc/socket.zig");

pub const Type = base.Type;

/// Kinds of IPC instances
pub const Kind = enum {
  socket,
};

pub const Params = union(Kind) {
  socket: socket.Params
};

pub const Ipc = union(Kind) {
  socket: socket.Ipc,

  pub fn init(params: Params, runtime: *Runtime, allocator: ?std.mem.Allocator) !Ipc {
    return switch (params) {
      .socket => |params_socket| .{
        .socket = try socket.Ipc.init(params_socket, runtime, allocator),
      },
    };
  }

  pub fn ref(self: *Ipc, allocator: ?std.mem.Allocator) Ipc {
    return switch (self.*) {
      .socket => |socket_ipc| .{
        .socket = try socket_ipc.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Ipc) !void {
    return switch (self.*) {
      .socket => self.socket.unref(),
    };
  }
  
  pub fn toBase(self: *Ipc) base.Ipc {
    return switch (self) {
      .socket => |socket_ipc| socket_ipc.toBase(),
    };
  }
};
