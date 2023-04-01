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
  dir: ?[]const u8,
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
    self.type.allocator.free(self.dir);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
dir: []const u8,
ipc: ipc.Ipc,
mode: Mode,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  const t = Type.init(parent, allocator);

  var self = Self {
    .type = t,
    .mode = params.mode,
    .dir = try (if (params.dir) |value| t.allocator.dupe(u8, value)
      else (if (std.os.getenv("XDG_RUNTIME_DIR")) |xdg_runtime_dir| t.allocator.dupe(u8, xdg_runtime_dir) else std.process.getCwdAlloc(t.allocator))),
    .ipc = undefined,
  };

  errdefer t.allocator.free(self.dir);

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
