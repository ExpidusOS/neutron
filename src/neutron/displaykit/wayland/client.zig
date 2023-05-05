const builtin = @import("builtin");
const std = @import("std");
const xev = @import("xev");
const elemental = @import("../../elemental.zig");
const hardware = @import("../../hardware.zig");
const graphics = @import("../../graphics.zig");
const eglApi = @import("../../graphics/api/egl.zig");
const Runtime = @import("../../runtime/runtime.zig");
const FrameBuffer = @import("fb.zig");
const Self = @This();

const Context = @import("../base/context.zig");
const Client = @import("../base/client.zig");

const wayland = @import("wayland").client;
const wl = wayland.wl;
const xdg = wayland.xdg;
const zwp = wayland.zwp;

pub const Params = struct {
  renderer: ?graphics.renderer.Params,
  display: ?[]const u8,
  width: usize,
  height: usize,
};

const vtable = Client.VTable {
  .context = .{},
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
        self.compositor = registry.bind(global.name, wl.Compositor, 1) catch return;
      } else if (std.cstr.cmp(global.interface, wl.Shm.getInterface().name) == 0) {
        self.shm = registry.bind(global.name, wl.Shm, 1) catch return;
      } else if (std.cstr.cmp(global.interface, xdg.WmBase.getInterface().name) == 0) {
        self.wm_base = registry.bind(global.name, xdg.WmBase, 1) catch return;
      } else if (std.cstr.cmp(global.interface, zwp.LinuxDmabufV1.getInterface().name) == 0) {
        self.dmabuf = registry.bind(global.name, zwp.LinuxDmabufV1, 1) catch return;
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
      .surface = undefined,
      .completion = undefined,
    };

    const registry = try self.wl_display.getRegistry();

    registry.setListener(*Self, registryListener, self);
    if (self.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    const compositor = self.compositor orelse return error.NoCompositor;
    const shm = self.shm orelse return error.NoShm;
    const wm_base = self.wm_base orelse return error.NoWmBase;
    const dmabuf = self.dmabuf orelse return error.NoWmBase;

    _ = try hardware.base.device.Gpu.init(&self.base_gpu, .{
      .vtable = &gpu_vtable,
    }, self, t.allocator);

    _ = shm;
    _ = wm_base;
    _ = dmabuf;

    self.surface = try compositor.createSurface();
    self.surface.commit();
    if (self.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    _ = try Client.init(&self.base_client, .{
      .vtable = &vtable,
      .renderer = params.renderer,
      .gpu = &self.base_gpu,
    }, self, self.type.allocator);

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
    };

    _ = try self.base_client.type.refInit(&dest.base_client);
    _ = try self.base_gpu.type.refInit(&dest.base_gpu);
  }

  pub fn unref(self: *Self) void {
    self.base_client.unref();
    self.base_gpu.unref();
    self.surface.destroy();
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
surface: *wl.Surface,
completion: xev.Completion,

pub usingnamespace Type.Impl;

pub inline fn getRuntime(self: *Self) *Runtime {
  return Runtime.Type.fromOpaque(self.type.parent.?.getValue());
}
