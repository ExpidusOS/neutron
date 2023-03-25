const std = @import("std");
const elemental = @import("../../../elemental.zig");
const rpc = @import("../base.zig");

pub const Implementation = rpc.Implementation(std.net.Stream.Reader, std.net.Stream.Writer);

pub fn newClient(stream: std.net.Stream, allocator: ?std.mem.Allocator) !*Implementation.Client {
  if (allocator == null) {
    return newClient(stream, std.heap.page_allocator);
  }

  return try Implementation.Client.new(.{
    .endpoint = Implementation.Client.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
  }, allocator);
}

pub fn newHost(stream: std.net.Stream, allocator: ?std.mem.Allocator) !*Implementation.Host {
  if (allocator == null) {
    return newHost(stream, std.heap.page_allocator);
  }

  return try Implementation.Host.new(.{
    .endpoint = Implementation.Host.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
  }, allocator);
}

pub fn new(t: rpc.TypeOf, stream: std.net.Stream, allocator: ?std.mem.Allocator) !Implementation.OneOf {
  return try Implementation.OneOf.new(t, switch (t) {
    .client => Implementation.Client.Params {
      .endpoint = Implementation.Client.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
    },
    .host => Implementation.Host.Params {
      .endpoint = Implementation.Host.EndPoint.init(allocator.?, stream.reader(), stream.writer()),
    },
  }, allocator);
}

pub const Client = Implementation.Client;
pub const Server = @import("stream/server.zig");

pub const TypeOf = enum {
  client,
  server,
};

pub const OneOf = union(TypeOf) {
  client: *Client,
  server: *Server,
};
