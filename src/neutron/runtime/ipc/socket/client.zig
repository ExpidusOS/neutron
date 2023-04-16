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
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base_client = try base.Client.init(.{
        .runtime = params.runtime,
      }, self, self.type.allocator),
      .base = try Base.init(.{
        .vtable = &.{
          .get_fd = get_fd,
        },
        .base = &self.base_client.base,
        .runtime = params.runtime,
      }, self, self.type.allocator),
      .fd = try std.os.socket(params.address.any.family,
        std.os.SOCK.STREAM | std.os.SOCK.NONBLOCK | (if (builtin.target.os.tag == .windows) 0 else std.os.SOCK.CLOEXEC),
        (if (params.address.any.family == std.os.AF.UNIX) @as(u32, 0) else std.os.IPPROTO.TCP)),
    };
    errdefer std.os.closeSocket(self.fd);
    errdefer self.base_client.unref();
    errdefer self.base.unref();
    try std.os.connect(self.fd, &params.address.any, params.address.getOsSockLen());
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
      .base_client = try self.base_client.type.refInit(t.allocator),
      .fd = self.fd,
    };
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.base_client.unref();
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

pub inline fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return Type.init(params, parent, allocator);
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}
