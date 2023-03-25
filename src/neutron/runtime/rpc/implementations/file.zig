const std = @import("std");
const elemental = @import("../../../elemental.zig");
const rpc = @import("../base.zig");

pub const Implementation = rpc.Implementation(std.fs.File.Reader, std.fs.File.Writer);

pub fn newClient(file: std.fs.File, allocator: ?std.mem.Allocator) !*Implementation.Client {
  if (allocator == null) {
    return newClient(file, std.mem.page_allocator);
  }

  return try Implementation.Client.new(.{
    .endpoint = Implementation.Client.EndPoint.init(allocator.?, file.reader(), file.writer()),
  }, allocator);
}

pub fn newHost(file: std.fs.File, allocator: ?std.mem.Allocator) !*Implementation.Host {
  if (allocator == null) {
    return newHost(file, std.mem.page_allocator);
  }

  return try Implementation.Host.new(.{
    .endpoint = Implementation.Host.EndPoint.init(allocator.?, file.reader(), file.writer()),
  }, allocator);
}

pub fn new(t: rpc.TypeOf, file: std.fs.File, allocator: ?std.mem.Allocator) !Implementation.OneOf {
  return try Implementation.OneOf.new(t, switch (t) {
    .client => Implementation.Client.Params {
      .endpoint = Implementation.Client.EndPoint.init(allocator.?, file.reader(), file.writer()),
    },
    .host => Implementation.Host.Params {
      .endpoint = Implementation.Host.EndPoint.init(allocator.?, file.reader(), file.writer()),
    },
  }, allocator);
}
