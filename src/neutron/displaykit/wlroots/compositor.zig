const builtin = @import("builtin");
const std = @import("std");
const xev = @import("xev");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const graphics = @import("../../graphics.zig");
const flutter = @import("../../flutter.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Context = @import("../base/context.zig");
const Compositor = @import("../base/compositor.zig");
const BaseOutput = @import("../base/output.zig");
const Output = @import("output.zig");
const Input = @import("input.zig").Input;
const FrameBuffer = @import("fb.zig");
const Self = @This();

const c = hardware.device.Gpu.c;

const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {
  renderer: ?graphics.renderer.Params,
};

const vtable = Compositor.VTable {
  .context = .{
    .get_egl_image_khr_parameters = (struct {
      fn callback(_: *anyopaque, _fb: *graphics.FrameBuffer) !Context.EGLImageKHRParameters {
        return @fieldParentPtr(FrameBuffer, "base", _fb).getEGLImageKHRParameters();
      }
    }).callback,
    .get_outputs = (struct {
      fn callback(_context: *anyopaque) !*elemental.TypedList(*BaseOutput) {
        const context = Context.Type.fromOpaque(_context);
        const compositor = @fieldParentPtr(Compositor, "context", context);
        const self = @fieldParentPtr(Self, "base_compositor", compositor);

        const list = try elemental.TypedList(*BaseOutput).new(.{}, null, self.type.allocator);
        errdefer list.unref();

        for (self.outputs.items) |output| {
          try list.append(&output.base_output);
        }
        return list;
      }
    }).callback,
  },
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
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
      .base_compositor = undefined,
      .allocator = allocator,
      .seat = try wlr.Seat.create(self.wl_server, "default"),
      .cursor_mngr = try wlr.XcursorManager.create(null, 24),
      .scene = try wlr.Scene.create(),
      .output_layout = try wlr.OutputLayout.create(),
      .outputs = try elemental.TypedList(*Output).init(.{}, self, t.allocator),
      .inputs = try elemental.TypedList(*Input).init(.{}, self, t.allocator),
      .completion = undefined,
    };

    self.base_compositor = try Compositor.init(.{
      .vtable = &vtable,
      .renderer = params.renderer,
      .gpu = if (self.gpu) |*gpu| gpu else null,
    }, self, self.type.allocator);

    self.base_compositor.context.type.ref.value = &self.base_compositor.context;
    self.base_compositor.context.renderer.setDisplayKit(&self.base_compositor.context);

    try self.scene.attachOutputLayout(self.output_layout);

    self.backend.events.new_output.add(&self.output_new);
    self.backend.events.new_input.add(&self.input_new);

    var buff: [11]u8 = undefined;
    self.socket = try self.type.allocator.dupeZ(u8, try self.wl_server.addSocketAuto(&buff));

    try self.cursor_mngr.load(1);
    try self.backend.start();

    const runtime = self.getRuntime();
    const event_loop = self.wl_server.getEventLoop();

    self.completion = .{
      .op = .{
        .poll = .{
          .fd = event_loop.getFd(),
          .events = std.os.POLL.ERR | std.os.POLL.HUP | std.os.POLL.IN | std.os.POLL.NVAL | std.os.POLL.OUT | std.os.POLL.PRI | std.os.POLL.RDBAND | std.os.POLL.RDNORM,
        },
      },

      .userdata = self,
      .callback = (struct {
        fn callback(ud: ?*anyopaque, loop: *xev.Loop, completion: *xev.Completion, res: xev.Result) xev.CallbackAction {
          const compositor = Type.fromOpaque(ud.?);

          _ = loop;
          _ = completion;
          _ = res;

          const wl_loop = compositor.wl_server.getEventLoop();
          wl_loop.dispatch(0) catch |err| {
            // TODO: use logger
            std.debug.print("Failed to dispatch event: {s}\n", .{ @errorName(err) });
          };
          return .rearm;
        }
      }).callback,
    };

    runtime.loop.add(&self.completion);
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
      .gpu = try self.gpu.type.refInit(t.allocator),
      .completion = self.completion,
    };
  }

  pub fn unref(self: *Self) void {
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
completion: xev.Completion,
outputs: elemental.TypedList(*Output),
output_new: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init(output_new),
inputs: elemental.TypedList(*Input),
input_new: wl.Listener(*wlr.InputDevice) = wl.Listener(*wlr.InputDevice).init(input_new),
socket: [:0]const u8 = undefined,
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

  // FIXME: segment faults
  // output.unref();
  _ = output;
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
  return Runtime.Type.fromOpaque(self.type.parent.?.getValue());
}
