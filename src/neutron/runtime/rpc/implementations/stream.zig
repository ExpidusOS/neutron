const std = @import("std");
const elemental = @import("../../../elemental.zig");
const rpc = @import("../base.zig");
const Runtime = @import("../../runtime.zig");

pub const Implementation = @import("stream/base.zig").Implementation;

pub fn newClient(runtime: *Runtime, stream: std.net.Stream, allocator: ?std.mem.Allocator) !*Implementation.Client {
  if (allocator == null) {
    return newClient(runtime, stream, std.heap.page_allocator);
  }

  return try Implementation.Client.new(.{
    .endpoint = Implementation.Client.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
    .runtime = runtime,
  }, allocator);
}

pub fn newHost(runtime: *Runtime, stream: std.net.Stream, allocator: ?std.mem.Allocator) !*Implementation.Host {
  if (allocator == null) {
    return newHost(runtime, stream, std.heap.page_allocator);
  }

  return try Implementation.Host.new(.{
    .endpoint = Implementation.Host.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
    .runtime = runtime,
  }, allocator);
}

pub fn new(t: rpc.TypeOf, runtime: *Runtime, stream: std.net.Stream, allocator: ?std.mem.Allocator) !Implementation.OneOf {
  return try Implementation.OneOf.new(t, switch (t) {
    .client => Implementation.Client.Params {
      .runtime = runtime,
      .endpoint = Implementation.Client.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
    },
    .host => Implementation.Host.Params {
      .runtime = runtime,
      .endpoint = Implementation.Host.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
    },
  }, allocator);
}

pub const Client = Implementation.Client;
pub const Host = @import("stream/host.zig");
pub const Server = @import("stream/server.zig");

pub const TypeOf = enum {
  client,
  server,
};

pub const OneOf = union(TypeOf) {
  client: *Client,
  server: *Server,
};
