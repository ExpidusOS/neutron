const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Runtime = @import("../../runtime.zig");
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
    };
  }

  pub fn unref(self: *Self) !void {
    try self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,
fd: std.os.socket_t,

fn get_fd(_self: *anyopaque) std.os.socket_t {
  return Type.fromOpaque(_self).fd;
}

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  var self = Self {
    .type = Type.init(parent, allocator),
    .base = undefined,
    .fd = try std.os.socket(params.address.any.family,
      std.os.SOCK.STREAM | (if (builtin.target.os.tag == .windows) 0 else std.os.SOCK.CLOEXEC),
      (if (params.address.any.family == std.os.AF.UNIX) 0 else std.os.IPPROTO.TCP)),
  };
  errdefer std.os.closeSocket(self.fd);

  self.base = try Base.init(.{
    .vtable = &.{
      .get_fd = get_fd,
    },
    .runtime = params.runtime,
  }, &self, self.type.allocator);
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
