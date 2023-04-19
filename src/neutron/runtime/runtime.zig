const std = @import("std");
const elemental = @import("../elemental.zig");
const displaykit = @import("../displaykit.zig");
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
  ipcs: ?[]ipc.Params = null,
  display: ?displaykit.Params,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .mode = params.mode,
      .dir = try (if (params.dir) |value| t.allocator.dupe(u8, value)
        else (if (std.os.getenv("XDG_RUNTIME_DIR")) |xdg_runtime_dir| t.allocator.dupe(u8, xdg_runtime_dir) else std.process.getCwdAlloc(t.allocator))),
      .ipcs = std.ArrayList(ipc.Ipc).init(t.allocator),
      .displaykit = undefined,
    };

    errdefer t.allocator.free(self.dir);
    errdefer self.ipcs.deinit();

    if (params.ipcs) |ipcs| {
      for (ipcs) |ipc_params| {
        try self.ipcs.append(try ipc.Ipc.init(ipc_params, self, self.type.allocator));
      }
    }

    // TODO: determine a compatible displaykit backend based on the OS
    self.displaykit = try displaykit.Backend.init(if (params.display) |value| value else .{
      .wlroots = .{
        .base = .{
          .type = .compositor,
        },
      },
    }, self, t.allocator);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .mode = self.mode,
      .ipc = try self.ipc.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    for (self.ipcs.items) |ipc_obj| {
      @constCast(&ipc_obj).unref();
    }

    self.ipcs.deinit();
    self.type.allocator.free(self.dir);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
dir: []const u8,
ipcs: std.ArrayList(ipc.Ipc),
displaykit: displaykit.Backend,
mode: Mode,

pub usingnamespace Type.Impl;

pub fn run(self: *Self) void {
  _ = self;
  // TODO: run the flutter engine
  while (true) {}
}
