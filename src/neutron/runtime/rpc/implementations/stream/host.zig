const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../../../elemental.zig");
const Runtime = @import("../../../runtime.zig");
const impl = @import("base.zig");
const xev = @import("xev");
const Host = @This();

pub const Params = struct {
  runtime: *Runtime,
  stream: std.net.Stream,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo {
  .init = impl_init,
  .construct = impl_construct,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Host, Params, TypeInfo);

runtime: *Runtime,
impl: *impl.Implementation.Host,
stream: std.net.Stream,
thread: std.Thread,
loop: xev.Loop,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !*anyopaque {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  return &(Host {
    .runtime = params.runtime.ref(),
    .impl = try impl.Implementation.Host.new(.{
      .runtime = params.runtime,
      .endpoint = impl.Implementation.Host.EndPoint.init(allocator, params.stream.reader(), params.stream.writer()),
    }, allocator),
    .stream = params.stream,
    .thread = undefined,
    .loop = try xev.Loop.init(.{}),
  });
}

fn impl_construct(_self: *anyopaque, _: *anyopaque) !void {
  const self = @ptrCast(*Host, @alignCast(@alignOf(Host), _self));

  self.thread = try std.Thread.spawn(.{}, xev.Loop.run, .{ @constCast(&self.loop), xev.RunMode.until_done });
  try self.thread.setName("rpc-host");
}

fn impl_destroy(_self: *anyopaque) !void {
  const self = @ptrCast(*Host, @alignCast(@alignOf(Host), _self));

  self.loop.stop();
  // FIXME: we should join but the thread isn't stopping
  // self.thread.join();
  self.loop.deinit();
  self.impl.unref();
  self.stream.close();
  self.runtime.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Host, @alignCast(@alignOf(Host), _self));
  const dest = @ptrCast(*Host, @alignCast(@alignOf(Host), _dest));

  const params = Params {
    .runtime = self.runtime,
    .stream = self.stream,
  };

  dest.* = (try init(params, dest.getType().allocator)).instance;
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Host {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *Host) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *Host) *Host {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *Host) void {
  return self.getType().unref();
}

pub fn dupe(self: *Host) !*Host {
  return &(try self.getType().dupe()).instance;
}
