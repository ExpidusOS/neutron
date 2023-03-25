const std = @import("std");
const elemental = @import("../elemental.zig");
const displaykit = @import("../displaykit.zig");
const rpc = @import("rpc.zig").implementations.stream;
const Runtime = @This();

/// Mode to launch the runtime in
pub const Mode = enum {
  compositor,
  application
};

/// Instance creation parameters
pub const Params = struct {
  mode: Mode = Mode.application,
  path: []const u8
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(Runtime) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Runtime, Params, TypeInfo);

displaykit_context: *displaykit.Context,
rpc: rpc.OneOf,
mode: Mode,
path: []const u8,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Runtime {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  const dk_backend = try displaykit.Backends.get(.auto);

  const displaykit_context = switch (params.mode) {
    .compositor => &(try dk_backend.Compositor.new(.{}, allocator)).compositor.instance.context.instance,
    else => @panic("Runtime mode is missing the implementation"),
  };

  const socket = blk: {
    const dir = if (std.os.getenv("XDG_RUNTIME_DIR")) |value| try allocator.dupe(u8, value)
      else try std.process.getCwdAlloc(allocator);
    defer allocator.free(dir);

    break :blk try std.fs.path.join(allocator, &.{
      dir,
      "neutron.sock",
    });
  };
  defer allocator.free(socket);

  return .{
    .mode = params.mode,
    .path = params.path,
    .displaykit_context = displaykit_context,
    .rpc = switch (params.mode) {
      .compositor => .{
        .server = blk: {
          var server = std.net.StreamServer.init(.{});
          try server.listen(try std.net.Address.initUnix(socket));
          break :blk try rpc.Server.new(.{
            .server = server,
          }, allocator);
        },
      },
      .application => .{
        .client = try rpc.newClient(try std.net.connectUnixSocket(socket), allocator),
      },
    },
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*Runtime, @alignCast(@alignOf(Runtime), _self));
  self.displaykit_context.unref();

  switch (self.rpc) {
    .server => |server| {
      server.unref();
    },
    .client => |client| {
      client.unref();
    },
  }
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Runtime, @alignCast(@alignOf(Runtime), _self));
  const dest = @ptrCast(*Runtime, @alignCast(@alignOf(Runtime), _dest));

  dest.mode = self.mode;
  dest.path = self.path;
  dest.displaykit_context = try self.displaykit_context.dupe();
  dest.rpc = switch (self.rpc) {
    .server => |server| .{
      .server = try server.dupe(),
    },
    .client => |client| .{
      .client = try client.dupe(),
    },
  };
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Runtime {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *Runtime) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *Runtime) *Runtime {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *Runtime) void {
  return self.getType().unref();
}

pub fn dupe(self: *Runtime) !*Runtime {
  return &(try self.getType().dupe()).instance;
}
