const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Runtime = @import("../../runtime.zig");
const base = @import("../base.zig");
const Self = @This();

pub const VTable = struct {
  get_fd: *const fn (self: *anyopaque) std.os.socket_t,
};

pub const Params = struct {
  vtable: *const VTable,
  base: *base.Base,
  runtime: *Runtime,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .base = try self.base.ref(t.allocator),
      .vtable = self.vtable,
      .runtime = self.runtime,
    };
  }

  pub fn unref(self: *Self) !void {
    try self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: *base.Base,
vtable: *const VTable,
runtime: *Runtime,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  const t = Type.init(parent, allocator);
  var self = Self {
    .type = t,
    .base = try params.base.ref(t.allocator),
    .vtable = params.vtable,
    .runtime = params.runtime,
  };
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

pub inline fn getFd(self: *Self) std.os.socket_t {
  return self.vtable.get_fd(self.type.toOpaque());
}
