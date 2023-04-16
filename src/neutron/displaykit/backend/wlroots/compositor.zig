const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Compositor = @import("../base/compositor.zig");
const Self = @This();
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {};

const vtable = Compositor.VTable {
  .context = .{},
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .base_compositor = try self.base_compositor.type.refInit(t.allocator),
      .wl_server = self.wl_server,
      .backend = self.backend,
      .renderer = self.renderer,
      .allocator = self.allocator,
    };
  }

  pub fn unref(self: *Self) !void {
    try self.base_compositor.unref();

    self.wl_server.destroyClients();
    self.wl_server.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_compositor: Compositor,
wl_server: *wl.Server,
backend: *wlr.Backend,
renderer: *wlr.Renderer,
allocator: *wlr.Allocator,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  _ = params;
  const wl_server = try wl.Server.create();
  const backend = try wlr.Backend.autocreate(wl_server);
  const renderer = try wlr.Renderer.autocreate(backend);

  var self = Self {
    .type = Type.init(parent, allocator),
    .base_compositor = undefined,
    .wl_server = wl_server,
    .backend = backend,
    .renderer = renderer,
    .allocator = try wlr.Allocator.autocreate(backend, renderer),
  };

  self.base_compositor = try Compositor.init(.{
    .vtable = &vtable,
  }, &self, self.type.allocator);
  return self;
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self) !*Self {
  return self.type.refNew();
}

pub inline fn unref(self: *Self) !void {
  return self.type.unref();
}
