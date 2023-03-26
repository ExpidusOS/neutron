const std = @import("std");
const elemental = @import("../elemental.zig");
const displaykit = @import("../displaykit.zig");
const rpc = @import("rpc.zig").implementations.stream;
const xev = @import("xev");
const Runtime = @This();

/// Mode to launch the runtime in
pub const Mode = enum {
  compositor,
  application
};

/// Instance creation parameters
pub const Params = struct {
  mode: Mode = Mode.application,
  path: []const u8,
  runtime_dir: ?[]const u8 = null,
  socket_name: ?[]const u8 = null,
  socket_path: ?[]const u8 = null,
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
runtime_dir: []const u8,
socket_path: []const u8,
mode: Mode,
path: []const u8,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Runtime {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  const dk_backend = try displaykit.Backends.get(.auto);

  const displaykit_context = switch (params.mode) {
    .compositor => &(try dk_backend.Compositor.new(.{}, allocator)).compositor.instance.context.instance,
    else => @panic("Runtime mode is missing the implementation"),
  };

  const runtime_dir = if (params.runtime_dir) |value| try allocator.dupe(u8, value)
  else if (std.os.getenv("XDG_RUNTIME_DIR")) |value| try allocator.dupe(u8, value)
  else try std.process.getCwdAlloc(allocator);
  errdefer allocator.free(runtime_dir);

  const socket = if (params.socket_path) |value| try allocator.dupe(u8, value)
  else if (params.socket_name) |value| try std.fs.path.join(allocator, &.{
    runtime_dir,
    value,
  })
  else if (std.os.getenv("NEUTRON_SOCKET_NAME")) |value| try std.fs.path.join(allocator, &.{
    runtime_dir,
    value,
  })
  else if (std.os.getenv("NEUTRON_SOCKET_PATH")) |value| try allocator.dupe(u8, value)
  else blk: {
    var i: usize = 0;
    var diriter = try std.fs.openIterableDirAbsolute(runtime_dir, .{
      .access_sub_paths = false,
      .no_follow = true,
    });
    defer diriter.close();

    var iter = diriter.iterate();
    while (try iter.next()) |entry| {
      const str = try std.fmt.allocPrint(allocator, "neutron-{}.sock", .{ i });
      defer allocator.free(str);

      switch (params.mode) {
        .compositor => {
          if (std.mem.eql(u8, entry.name, str)) i += 1;
        },
        .application => {
          if (std.mem.eql(u8, entry.name, str)) break
          else if (std.mem.startsWith(u8, entry.name, "neutron-") and std.mem.endsWith(u8, entry.name, ".sock")) i += 1;
        },
      }
    }

    const fname = try std.fmt.allocPrint(allocator, "neutron-{}.sock", .{ i });
    defer allocator.free(fname);

    break :blk try std.fs.path.join(allocator, &.{
      runtime_dir,
      fname
    });
  };
  errdefer allocator.free(socket);

  return .{
    .mode = params.mode,
    .path = params.path,
    .displaykit_context = displaykit_context,
    .runtime_dir = runtime_dir,
    .socket_path = socket,
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

fn impl_construct(_self: *anyopaque, _: *anyopaque) !void {
  const self = @ptrCast(*Runtime, @alignCast(@alignOf(Runtime), _self));
  _ = self;
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

  std.fs.deleteFileAbsolute(self.socket_path) catch @panic("Failed to delete the socket");

  self.getType().allocator.free(self.runtime_dir);
  self.getType().allocator.free(self.socket_path);
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Runtime, @alignCast(@alignOf(Runtime), _self));
  const dest = @ptrCast(*Runtime, @alignCast(@alignOf(Runtime), _dest));

  dest.mode = self.mode;
  dest.path = self.path;
  dest.displaykit_context = try self.displaykit_context.dupe();
  dest.runtime_dir = try dest.getType().allocator.dupe(u8, self.runtime_dir);
  dest.socket_path = try dest.getType().allocator.dupe(u8, self.socket_path);
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
