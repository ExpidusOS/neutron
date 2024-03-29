const std = @import("std");
const xev = @import("xev");
const elemental = @import("../../../elemental.zig");
const Runtime = @import("../../runtime.zig");
const base = @import("../base.zig");
const Base = @import("base.zig");
const Self = @This();

pub const Params = struct {
  runtime: *Runtime,
  address: std.net.Address,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .address = undefined,
      .base_server = try base.Server.init(&self.base_server, .{
        .runtime = params.runtime,
      }, self, self.type.allocator),
      .base = try Base.init(&self.base, .{
        .vtable = &.{
          .get_fd = get_fd,
        },
        .base = &self.base_server.base,
        .runtime = params.runtime,
      }, self, self.type.allocator),
      .connections = std.ArrayList(std.os.socket_t).init(t.allocator),
      .fd = try std.os.socket(params.address.any.family, std.os.SOCK.STREAM | std.os.SOCK.NONBLOCK | std.os.SOCK.CLOEXEC,
        (if (params.address.any.family == std.os.AF.UNIX) @as(u32, 0) else std.os.IPPROTO.TCP)),
    };
    errdefer std.os.closeSocket(self.fd);

    var socklen = params.address.getOsSockLen();
    try std.os.bind(self.fd, &params.address.any, socklen);
    try std.os.listen(self.fd, 1);
    try std.os.getsockname(self.fd, &self.address.any, &socklen);

    // TODO: remove when not needed
    self.base.base.runtime.loop.add(@constCast(&xev.Completion {
      .op = .{
        .accept = .{
          .socket = self.fd,
        },
      },

      .userdata = self,
      .callback = (struct {
        fn callback(ud: ?*anyopaque, loop: *xev.Loop, completion: *xev.Completion, res: xev.Result) xev.CallbackAction {
          _ = loop;
          _ = completion;

          const server = Type.fromOpaque(ud.?);
          if (res.accept catch null) |fd| {
            server.connections.append(fd) catch unreachable;
            std.debug.print("Connected: {}\n", .{ fd });
            return .rearm;
          }
          return .rearm;
        }
      }).callback,
    }));
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .base_server = try self.base_server.type.refInit(t.allocator),
      .fd = self.fd,
      .connections = try std.ArrayList(std.os.socket_t).initCapacity(t.allocator, self.connections.capacity),
    };

    dest.connections.appendSliceAssumeCapacity(self.connections.items);
  }

  pub fn unref(self: *Self) void {
    self.connections.deinit();
    self.base.unref();
    self.base_server.unref();
    std.os.closeSocket(self.fd);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,
base_server: base.Server,
address: std.net.Address,
fd: std.os.socket_t,
connections: std.ArrayList(std.os.socket_t),

fn get_fd(_self: *anyopaque) std.os.socket_t {
  return Type.fromOpaque(_self).fd;
}

pub usingnamespace Type.Impl;
