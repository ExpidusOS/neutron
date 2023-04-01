const std = @import("std");
const elemental = @import("../elemental.zig");
const ipc = @import("ipc.zig");
const Self = @This();

pub const Mode = enum {
  compositor,
  application,

  pub fn getIpcType(self: Mode) ipc.Type {
    return switch (self) {
      .compositor => .server,
      .application => .client,
    };
  }
};

pub const Params = struct {
  mode: Mode = .application,
  ipc: ?ipc.Params = null,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .mode = self.mode,
      .ipc = try self.ipc.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) !void {
    try self.ipc.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
ipc: ipc.Ipc,
mode: Mode,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  var self = Self {
    .type = Type.init(parent, allocator),
    .mode = params.mode,
    .ipc = undefined,
  };

  self.ipc = try ipc.Ipc.init(
    if (params.ipc) |value| value
    else .{
      // TODO: maybe we should determine per-platform
      .socket = .{
        .base = .{
          .type = params.mode.getIpcType(),
        },
        .path = null,
      },
    },
    &self, allocator);
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
