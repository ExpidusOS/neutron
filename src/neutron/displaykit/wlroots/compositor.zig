const std = @import("std");
const elemental = @import("../../elemental.zig");
const Compositor = @import("../base/compositor.zig");
const Output = @import("output.zig");
const Self = @This();

const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {};

const vtable = Compositor.VTable {
  .context = .{},
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    _ = params;

    self.* = .{
      .type = t,
      .base_compositor = try Compositor.init(.{
        .vtable = &vtable,
      }, self, self.type.allocator),
      .wl_server = try wl.Server.create(),
      .backend = try wlr.Backend.autocreate(self.wl_server),
      .renderer = try wlr.Renderer.autocreate(self.backend),
      .allocator = try wlr.Allocator.autocreate(self.backend, self.renderer),
      .output_layout = try wlr.OutputLayout.create(),
      .outputs = try elemental.TypedList(*Output).init(.{}, self, t.allocator),
    };

    try self.renderer.initServer(self.wl_server);
    self.backend.events.new_output.add(&self.output_new);
    try self.backend.start();

    var buff: [11]u8 = undefined;
    self.socket = try self.wl_server.addSocketAuto(&buff);
    // TODO: wl_server.run() in a new thread
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_compositor = try self.base_compositor.type.refInit(t.allocator),
      .wl_server = self.wl_server,
      .backend = self.backend,
      .renderer = self.renderer,
      .allocator = self.allocator,
      .outputs = try self.outputs.clone(),
    };
  }

  pub fn unref(self: *Self) void {
    self.base_compositor.unref();
    self.outputs.deinit();

    self.wl_server.destroyClients();
    self.wl_server.destroy();

    self.backend.destroy();
    self.renderer.destroy();
    self.allocator.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_compositor: Compositor,
wl_server: *wl.Server,
backend: *wlr.Backend,
renderer: *wlr.Renderer,
allocator: *wlr.Allocator,
output_layout: *wlr.OutputLayout,
outputs: elemental.TypedList(*Output),
output_new: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init(output_new),
socket: [:0]const u8 = undefined,

fn output_new(listener: *wl.Listener(*wlr.Output), wlr_output: *wlr.Output) void {
  const self = @fieldParentPtr(Self, "output_new", listener);

  const output = Output.new(.{
    .context = &self.base_compositor.context,
    .value = wlr_output,
  }, self, self.type.allocator) catch {
    // TODO: use the logger
    return;
  };
  errdefer output.unref();

  self.outputs.append(output) catch {
    // TODO: use the logger
    return;
  };
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
