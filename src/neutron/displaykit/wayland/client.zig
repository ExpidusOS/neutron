const builtin = @import("builtin");
const std = @import("std");
const xev = @import("xev");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const graphics = @import("../../graphics.zig");
const eglApi = @import("../../graphics/api/egl.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Context = @import("../base/context.zig");
const BaseOutput = @import("../base/output.zig");
const BaseView = @import("../base/view.zig");
const Client = @import("../base/client.zig");
const Output = @import("output.zig");
const View = @import("view.zig");
const Self = @This();

const wayland = @import("wayland").client;
const wl = wayland.wl;
const xdg = wayland.xdg;
const zwp = wayland.zwp;

pub const Params = struct {
  renderer: ?graphics.renderer.Params,
  display: ?[]const u8,
  width: i32,
  height: i32,
};

const vtable = Client.VTable {
  .context = .{
    .get_outputs = (struct {
      fn callback(_context: *anyopaque) !*elemental.TypedList(*BaseOutput) {
        const context = Context.Type.fromOpaque(_context);
        const client = @fieldParentPtr(Client, "context", context);
        const self = @fieldParentPtr(Self, "base_client", client);

        const list = try elemental.TypedList(*BaseOutput).new(.{}, null, self.type.allocator);
        errdefer list.unref();

        for (self.outputs.items) |output| {
          try list.append(&output.base_output);
        }
        return list;
      }
    }).callback,
    .get_views = (struct {
      fn callback(_context: *anyopaque) !*elemental.TypedList(*BaseView) {
        const context = Context.Type.fromOpaque(_context);
        const client = @fieldParentPtr(Client, "context", context);
        const self = @fieldParentPtr(Self, "base_client", client);

        const list = try elemental.TypedList(*BaseView).new(.{}, null, self.type.allocator);
        errdefer list.unref();

        try list.append(&self.view.base_view);
        return list;
      }
    }).callback,
  },
};

const gpu_vtable = hardware.base.device.Gpu.VTable {
  .base = .{},
  .get_egl_display = (struct {
    fn callback(_gpu: *anyopaque) !eglApi.c.EGLDisplay {
      const gpu = hardware.base.device.Gpu.Type.fromOpaque(_gpu);
      const self = @fieldParentPtr(Self, "base_gpu", gpu);

      if (eglApi.hasClientExtension("EGL_EXT_platform_base")) {
        const eglGetPlatformDisplayEXT = try eglApi.tryResolve(eglApi.c.PFNEGLGETPLATFORMDISPLAYEXTPROC, "eglGetPlatformDisplayEXT");
        const display = eglGetPlatformDisplayEXT(eglApi.c.EGL_PLATFORM_WAYLAND_KHR, self.wl_display, null);
        if (display == eglApi.c.EGL_NO_DISPLAY) return error.EglNoDisplay;
        return display;
      }

      const display = eglApi.c.eglGetDisplay(self.wl_display);
      if (display == eglApi.c.EGL_NO_DISPLAY) return error.EglNoDisplay;
      return display;
    }
  }).callback,
};

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, self: *Self) void {
  switch (event) {
    .global => |global| {
      if (std.cstr.cmp(global.interface, wl.Compositor.getInterface().name) == 0) {
        self.compositor = registry.bind(global.name, wl.Compositor, @intCast(u32, wl.Compositor.getInterface().version)) catch return;
      } else if (std.cstr.cmp(global.interface, wl.Shm.getInterface().name) == 0) {
        self.shm = registry.bind(global.name, wl.Shm, @intCast(u32, wl.Shm.getInterface().version)) catch return;
      } else if (std.cstr.cmp(global.interface, wl.Output.getInterface().name) == 0) {
        const wl_output = registry.bind(global.name, wl.Output, @intCast(u32, wl.Output.getInterface().version)) catch return;
        const output = Output.new(.{
          .context = &self.base_client.context,
          .value = wl_output,
        }, null, self.type.allocator) catch return;

        self.outputs.appendOwned(output) catch return;
      } else if (std.cstr.cmp(global.interface, xdg.WmBase.getInterface().name) == 0) {
        self.wm_base = registry.bind(global.name, xdg.WmBase, @intCast(u32, xdg.WmBase.getInterface().version)) catch return;
      } else if (std.cstr.cmp(global.interface, zwp.LinuxDmabufV1.getInterface().name) == 0) {
        self.dmabuf = registry.bind(global.name, zwp.LinuxDmabufV1, @intCast(u32, zwp.LinuxDmabufV1.getInterface().version)) catch return;
      } else {
        std.debug.print("{s}\n", .{ global.interface });
      }
    },
    .global_remove => {
      // TODO
    },
  }
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    const display = if (params.display) |v| try t.allocator.dupeZ(u8, v) else null;
    defer if (display) |d| t.allocator.free(d);

    self.* = .{
      .type = t,
      .base_client = undefined,
      .base_gpu = undefined,
      .wl_display = try wl.Display.connect(if (display) |d| d.ptr else null),
      .compositor = null,
      .shm = null,
      .wm_base = null,
      .dmabuf = null,
      .completion = undefined,
      .outputs = try elemental.TypedList(*Output).new(.{}, null, t.allocator),
      .view = undefined,
    };

    const registry = try self.wl_display.getRegistry();

    registry.setListener(*Self, registryListener, self);
    if (self.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    if (self.compositor == null) return error.NoCompositor;
    if (self.shm == null) return error.NoShm;
    if (self.wm_base == null) return error.NoWmBase;
    if (self.dmabuf == null) return error.NoWmBase;

    _ = try hardware.base.device.Gpu.init(&self.base_gpu, .{
      .vtable = &gpu_vtable,
    }, self, t.allocator);

    _ = try Client.init(&self.base_client, .{
      .vtable = &vtable,
      .renderer = params.renderer,
      .gpu = &self.base_gpu,
    }, self, self.type.allocator);

    self.view = try View.new(.{
      .context = &self.base_client.context,
      .resolution = .{ params.width, params.height },
    }, null, self.type.allocator);

    const runtime = self.getRuntime();

    self.completion = .{
      .op = .{
        .poll = .{
          .fd = self.wl_display.getFd(),
          .events = std.os.POLL.IN,
        },
      },

      .userdata = self,
      .callback = (struct {
        fn callback(ud: ?*anyopaque, loop: *xev.Loop, completion: *xev.Completion, res: xev.Result) xev.CallbackAction {
          const client = Type.fromOpaque(ud.?);

          _ = loop;
          _ = completion;
          _ = res;

          return if (client.wl_display.dispatch() == .SUCCESS) .rearm else .disarm;
        }
      }).callback,
    };

    runtime.loop.add(&self.completion);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_client = undefined,
      .wl_display = self.wl_display,
      .shm = self.shm,
      .compositor = self.compositor,
      .wm_base = self.wm_base,
      .dmabuf = self.dmabuf,
      .surface = self.surface,
      .compositor = self.compositor,
      .outputs = try self.outputs.ref(t.allocator),
      .view = try self.view.ref(t.allocator),
    };

    _ = try self.base_client.type.refInit(&dest.base_client, t.allocator);
    _ = try self.base_gpu.type.refInit(&dest.base_gpu, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.view.unref();
    self.outputs.unref();
    self.base_client.unref();
    self.base_gpu.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_client: Client,
base_gpu: hardware.base.device.Gpu,
wl_display: *wl.Display,
shm: ?*wl.Shm,
compositor: ?*wl.Compositor,
wm_base: ?*xdg.WmBase,
dmabuf: ?*zwp.LinuxDmabufV1,
completion: xev.Completion,
outputs: *elemental.TypedList(*Output),
view: *View,

pub usingnamespace Type.Impl;

pub inline fn getRuntime(self: *Self) *Runtime {
  return Runtime.Type.fromOpaque(self.type.parent.?.getValue());
}
