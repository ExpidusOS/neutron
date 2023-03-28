const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../../../elemental.zig");
const Runtime = @import("../../../runtime.zig");
const xev = @import("xev");
const Host = @import("host.zig");
const Server = @This();

const HostArrayList = elemental.TypedList(Host, Host.Params, Host.TypeInfo);

pub const Params = struct {
  server: std.net.StreamServer,
  runtime: *Runtime,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo {
  .init = impl_init,
  .construct = impl_construct,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Server, Params, TypeInfo);

runtime: *Runtime,
hosts: *HostArrayList,
server: std.net.StreamServer,
thread: std.Thread,
loop: xev.Loop,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !*anyopaque {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  return &(Server {
    .runtime = params.runtime.ref(),
    .hosts = try HostArrayList.new(.{
      .list = null,
    }, allocator),
    .server = params.server,
    .thread = undefined,
    .loop = try xev.Loop.init(.{}),
  });
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
          
          const host = Host.new(.{
            .runtime = server.runtime,
            .stream = stream,
          }, server.getType().allocator) catch unreachable;
          server.hosts.append(host.getType()) catch unreachable;
        }
        return .rearm;
      }
    }).callback,
  });

  self.thread = try std.Thread.spawn(.{}, xev.Loop.run, .{ @constCast(&self.loop), xev.RunMode.until_done });
  try self.thread.setName("rpc-server");
}

fn impl_destroy(_self: *anyopaque) !void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));

  self.loop.stop();
  // FIXME: we should join but the thread isn't stopping
  // self.thread.join();
  self.loop.deinit();
  self.hosts.unref();
  self.server.close();
  self.runtime.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));
  const dest = @ptrCast(*Server, @alignCast(@alignOf(Server), _dest));

  const params = Params {
    .runtime = self.runtime,
    .server = self.server,
  };

  dest.* = (try init(params, dest.getType().allocator)).instance;
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Server {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
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
