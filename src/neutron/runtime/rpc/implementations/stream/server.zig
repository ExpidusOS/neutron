const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../../../elemental.zig");
const impl = @import("../stream.zig");
const xev = @import("xev");
const Server = @This();

pub const Params = struct {
  server: std.net.StreamServer,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(Server) {
  .init = impl_init,
  .construct = impl_construct,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Server, Params, TypeInfo);

server: std.net.StreamServer,
thread: std.Thread,
loop: xev.Loop,

fn impl_init(_params: *anyopaque, _: std.mem.Allocator) !Server {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  return .{
    .server = params.server,
    .thread = undefined,
    .loop = try xev.Loop.init(.{}),
  };
}

fn impl_construct(_self: *anyopaque, _: *anyopaque) !void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));

  self.loop.add(&xev.Completion {
    .op = .{
      .accept = .{
        .socket = self.server.sockfd.?,
      },
    },

    .userdata = self,
    .callback = (struct {
      fn callback(
        ud: ?*anyopaque,
        l: *xev.Loop,
        c: *xev.Completion,
        r: xev.Result,
      ) xev.CallbackAction {
        _ = l;
        _ = c;

        const server = @ptrCast(*Server, @alignCast(@alignOf(Server), ud.?));
        if (r.accept catch null) |fd| {
          const stream = std.net.Stream {
            .handle = fd,
          };

          const host = impl.newHost(stream, server.getType().allocator) catch null;
          if (host == null) return .rearm;

          defer host.?.unref();
          host.?.endpoint.acceptCalls() catch unreachable;
        }
        return .rearm;
      }
    }).callback,
  });

  self.thread = try std.Thread.spawn(.{}, xev.Loop.run, .{ @constCast(&self.loop), xev.RunMode.until_done });
  try self.thread.setName("rpc-server");
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));

  self.loop.stop();
  // FIXME: we should join but the thread isn't stopping
  // self.thread.join();
  self.loop.deinit();
  self.server.close();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));
  const dest = @ptrCast(*Server, @alignCast(@alignOf(Server), _dest));

  dest.server = self.server;
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Server {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Server {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *Server) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *Server) *Server {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *Server) void {
  return self.getType().unref();
}

pub fn dupe(self: *Server) !*Server {
  return &(try self.getType().dupe()).instance;
}
