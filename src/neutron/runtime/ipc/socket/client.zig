const builtin = @import("builtin");
const std = @import("std");
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
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .base_client = try self.base_client.type.refInit(t.allocator),
      .fd = self.fd,
    };
  }

  pub fn unref(self: *Self) !void {
    try self.base.unref();
    try self.base_client.unref();
    std.os.closeSocket(self.fd);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,
base_client: base.Client,
fd: std.os.socket_t,

fn get_fd(_self: *anyopaque) std.os.socket_t {
  return Type.fromOpaque(_self).fd;
}

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  var self = Self {
    .type = Type.init(parent, allocator),
    .base = undefined,
    .base_client = undefined,
    .fd = try std.os.socket(params.address.any.family,
      std.os.SOCK.STREAM | std.os.SOCK.NONBLOCK | (if (builtin.target.os.tag == .windows) 0 else std.os.SOCK.CLOEXEC),
      (if (params.address.any.family == std.os.AF.UNIX) @as(u32, 0) else std.os.IPPROTO.TCP)),
  };
  errdefer std.os.closeSocket(self.fd);

  self.base_client = try base.Client.init(.{
    .runtime = params.runtime,
  }, &self, self.type.allocator);
  errdefer self.base_client.unref() catch @panic("Failed to clean up base_client");

  self.base = try Base.init(.{
    .vtable = &.{
      .get_fd = get_fd,
    },
    .base = &self.base_client.base,
    .runtime = params.runtime,
  }, &self, self.type.allocator);
  errdefer self.base.unref() catch @panic("Failed to clean up base");

  try std.os.connect(self.fd, &params.address.any, params.address.getOsSockLen());
  return self;
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) !void {
  return self.type.unref();
}
