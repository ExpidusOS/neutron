const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Compositor = @import("../base/compositor.zig");
const Output = @import("output.zig");
const Input = @import("input.zig").Input;
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

    wlr.log.init(if (builtin.mode == .Debug) .debug else .err);

    self.* = .{
      .type = t,
      .base_compositor = try Compositor.init(.{
        .vtable = &vtable,
      }, self, self.type.allocator),
      .wl_server = try wl.Server.create(),
      .backend = try wlr.Backend.autocreate(self.wl_server),
      .renderer = try wlr.Renderer.autocreate(self.backend),
      .allocator = try wlr.Allocator.autocreate(self.backend, self.renderer),
      .seat = try wlr.Seat.create(self.wl_server, "default"),
      .cursor_mngr = try wlr.XcursorManager.create(null, 24),
      .scene = try wlr.Scene.create(),
      .output_layout = try wlr.OutputLayout.create(),
      .outputs = try elemental.TypedList(*Output).init(.{}, self, t.allocator),
      .inputs = try elemental.TypedList(*Input).init(.{}, self, t.allocator),
      .thread = try std.Thread.spawn(.{}, (struct {
        fn callback(compositor: *Self) !void {
          compositor.wl_server.run();
        }
      }).callback, .{ self }),
      .gpu = try hardware.device.Gpu.init(.{
        .fd = self.backend.getDrmFd(),
      }, self, t.allocator),
    };

    try self.renderer.initServer(self.wl_server);
    try self.scene.attachOutputLayout(self.output_layout);

    self.backend.events.new_output.add(&self.output_new);
    self.backend.events.new_input.add(&self.input_new);

    var buff: [11]u8 = undefined;
    self.socket = try self.type.allocator.dupeZ(u8, try self.wl_server.addSocketAuto(&buff));

    _ = try wlr.Compositor.create(self.wl_server, self.renderer);
    _ = try wlr.Subcompositor.create(self.wl_server);
    _ = try wlr.DataDeviceManager.create(self.wl_server);
    try self.cursor_mngr.load(1);

    const egl = self.gpu.getEglDisplay();
    _ = egl;

    try self.backend.start();
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_compositor = try self.base_compositor.type.refInit(t.allocator),
      .wl_server = self.wl_server,
      .backend = self.backend,
      .renderer = self.renderer,
      .allocator = self.allocator,
      .seat = self.seat,
      .cursor_mngr = self.cursor_mngr,
      .scene = self.scene,
      .output_layout = self.output_layout,
      .outputs = try self.outputs.type.refInit(t.allocator),
      .inputs = try self.inputs.type.refInit(t.allocator),
      .socket = try t.allocator.dupeZ(u8, self.socket),
      .thread = self.thread,
      .gpu = try self.gpu.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.thread.join();

    self.base_compositor.unref();

    self.outputs.deinit();
    self.inputs.deinit();

    self.gpu.unref();

    self.type.allocator.free(self.socket);

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
seat: *wlr.Seat,
cursor_mngr: *wlr.XcursorManager,
output_layout: *wlr.OutputLayout,
scene: *wlr.Scene,
outputs: elemental.TypedList(*Output),
output_new: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init(output_new),
inputs: elemental.TypedList(*Input),
input_new: wl.Listener(*wlr.InputDevice) = wl.Listener(*wlr.InputDevice).init(input_new),
socket: [:0]const u8 = undefined,
thread: std.Thread,
gpu: hardware.device.Gpu,

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

fn input_new(listener: *wl.Listener(*wlr.InputDevice), wlr_input: *wlr.InputDevice) void {
  const self = @fieldParentPtr(Self, "input_new", listener);

  const input = Input.new(wlr_input, self, self.type.allocator) catch {
    // TODO: use the logger
    return;
  };
  errdefer input.unref();

  self.inputs.append(input) catch {
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

pub inline fn getRuntime(self: *Self) *Runtime {
  return Runtime.Type.fromOpaque(self.type.parent.?);
}
