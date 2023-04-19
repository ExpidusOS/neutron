const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const graphics = @import("../../graphics.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Context = @import("../base/context.zig");
const Compositor = @import("../base/compositor.zig");
const Output = @import("output.zig");
const Input = @import("input.zig").Input;
const Self = @This();

const c = hardware.device.Gpu.c;

const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {};

const vtable = Compositor.VTable {
  .context = .{
    .create_render_surface = (struct {
      fn callback(_base_context: *anyopaque, res: @Vector(2, i32), visual: u32) !*anyopaque {
        const base_context = Context.Type.fromOpaque(_base_context);
        const gpu = base_context.gpu.?;

        if (@hasDecl(c, "gbm_surface_create_with_modifiers")) {
          return if (c.gbm_surface_create_with_modifiers(@ptrCast(*c.struct_gbm_device, gpu.gbm_dev), @intCast(u32, res[0]), @intCast(u32, res[1]), visual, &[_]u64 { 0 }, 1)) |value| value else error.InvalidGbm;
        }

        return if (c.gbm_surface_create(@ptrCast(*c.struct_gbm_device, gpu.gbm_dev), @intCast(u32, res[0]), @intCast(u32, res[1]), visual, c.GBM_BO_USE_SCANOUT | c.GBM_BO_USE_RENDERING)) |value| value else error.InvalidGbm;
      }
    }).callback,
    .resize_render_surface = (struct {
      fn callback(_base_context: *anyopaque, surf: *anyopaque, res: @Vector(2, i32)) !void {
        _ = _base_context;
        _ = surf;
        _ = res;
        return error.InvalidSurface;
      }
    }).callback,
    .get_render_surface_buffer = (struct {
      fn callback(_base_context: *anyopaque, surf: *anyopaque) !*graphics.FrameBuffer {
        const base_context = Context.Type.fromOpaque(_base_context);
        const gpu = base_context.gpu.?;
        return if (c.gbm_surface_lock_front_buffer(@ptrCast(*c.struct_gbm_surface, surf))) |bo| gpu.getGBMFrameBuffer(bo) else error.GbmFailure;
      }
    }).callback,
    .commit_render_surface_buffer = (struct {
      fn callback(_base_context: *anyopaque, surf: *anyopaque, _fb: *graphics.FrameBuffer) !void {
        _ = _base_context;
        const fb = hardware.device.Gpu.FrameBuffer.Type.fromOpaque(_fb);

        c.gbm_surface_release_buffer(@ptrCast(*c.struct_gbm_surface, surf), fb.gbm_bo);
      }
    }).callback,
    .destroy_render_surface = (struct {
      fn callback(_base_context: *anyopaque, surf: *anyopaque) void {
        _ = _base_context;
        c.gbm_surface_destroy(@ptrCast(*c.struct_gbm_surface, surf));
      }
    }).callback,
  },
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    _ = params;

    wlr.log.init(if (builtin.mode == .Debug) .debug else .err);

    const wl_server = try wl.Server.create();
    const backend = try wlr.Backend.autocreate(wl_server);
    const renderer = try wlr.Renderer.autocreate(backend);
    const allocator = try wlr.Allocator.autocreate(backend, renderer);

    try renderer.initServer(wl_server);

    _ = try wlr.Compositor.create(wl_server, renderer);
    _ = try wlr.Subcompositor.create(wl_server);
    _ = try wlr.DataDeviceManager.create(wl_server);

    self.* = .{
      .type = t,
      .wl_server = wl_server,
      .backend = backend,
      .renderer = renderer,
      .gpu = hardware.device.Gpu.init(.{
        .fd = backend.getDrmFd(),
      }, self, t.allocator) catch null,
      .base_compositor = try Compositor.init(.{
        .vtable = &vtable,
        .gpu = if (self.gpu) |gpu| @constCast(&gpu) else null,
      }, self, self.type.allocator),
      .allocator = allocator,
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
    };

    try self.scene.attachOutputLayout(self.output_layout);

    self.backend.events.new_output.add(&self.output_new);
    self.backend.events.new_input.add(&self.input_new);

    var buff: [11]u8 = undefined;
    self.socket = try self.type.allocator.dupeZ(u8, try self.wl_server.addSocketAuto(&buff));

    try self.cursor_mngr.load(1);
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
gpu: ?hardware.device.Gpu,

fn output_new(listener: *wl.Listener(*wlr.Output), wlr_output: *wlr.Output) void {
  const self = @fieldParentPtr(Self, "output_new", listener);

  const output = Output.new(.{
    .context = &self.base_compositor.context,
    .value = wlr_output,
  }, self, self.type.allocator) catch |err| {
    // TODO: use the logger
    std.debug.print("Failed to create output: {s}\n", .{ @errorName(err) });
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

pub usingnamespace Type.Impl;

pub inline fn getRuntime(self: *Self) *Runtime {
  return Runtime.Type.fromOpaque(self.type.parent.?);
}
