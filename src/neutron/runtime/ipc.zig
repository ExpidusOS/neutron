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
  socket: socket.Params,

  pub fn init(comptime kind: Kind) Params {
    return switch (kind) {
      .socket => .{
        .socket = socket.Params.init(),
      },
    };
  }

  /// A zig-clap compatible parser for generating parameters
  pub fn parseArgument(arg: []const u8) !Params {
    inline for (comptime std.meta.fields(Params), comptime std.meta.fields(Kind)) |u_field, e_field| {
      const arg_kind_sep = if (std.mem.indexOf(u8, arg, ":")) |value| value else arg.len;
      if (std.mem.eql(u8, arg[0..arg_kind_sep], u_field.name)) {
        var p = Params.init(@intToEnum(Kind, e_field.value));
        const start_index = if (arg_kind_sep + 1 < arg.len) arg_kind_sep + 1 else arg.len;
        @field(p, u_field.name) = try u_field.type.parseArgument(arg[start_index..]);
        return p;
      }
    }
    return error.InvalidKind;
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.writeAll(switch (self) {
      .socket => "socket",
    });

    try writer.writeByte(':');
    return switch (self) {
      .socket => |s| s.format(fmt, options, writer),
    };
  }
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

  pub fn ref(self: *Ipc, allocator: ?std.mem.Allocator) !Ipc {
    return switch (self.*) {
      .socket => .{
        .socket = try self.socket.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Ipc) void {
    return switch (self.*) {
      .socket => self.socket.unref(),
    };
  }
  
  pub fn toBase(self: *Ipc) base.Ipc {
    return switch (self.*) {
      .socket => self.socket.toBase(),
    };
  }
};
