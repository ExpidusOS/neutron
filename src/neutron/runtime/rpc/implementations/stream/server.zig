const std = @import("std");
const elemental = @import("../../../../elemental.zig");
const impl = @import("../stream.zig");
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
host_threads: std.ArrayList(std.Thread),
running: bool,

fn thread_main(self: *Server, conn: ?std.net.StreamServer.Connection) !void {
  if (conn == null) {
    while (self.running) {
      // TODO: we should log the errors
      try self.host_threads.append(try std.Thread.spawn(.{}, thread_main, .{
        self,
        try self.server.accept(),
      }));
    }
  } else {
    const host = try impl.newHost(conn.?.stream, self.getType().allocator);
    try host.endpoint.acceptCalls();
  }
}

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Server {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  return .{
    .server = params.server,
    .thread = undefined,
    .host_threads = std.ArrayList(std.Thread).init(allocator),
    .running = false,
  };
}

fn impl_construct(_self: *anyopaque, _: *anyopaque) !void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));
  self.running = true;
  self.thread = try std.Thread.spawn(.{}, thread_main, .{ self, null });
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*Server, @alignCast(@alignOf(Server), _self));
  self.running = false;
  self.thread.join();
  self.host_threads.deinit();
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
