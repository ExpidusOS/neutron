const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const BaseClient = @import("../base/client.zig");
const Context = @import("../base/context.zig");
const View = @import("../base/view.zig");
const Client = @import("client.zig");
const FrameBuffer = @import("fb.zig");
const Self = @This();

const c = @cImport({
  @cInclude("drm/drm_fourcc.h");
});

const wayland = @import("wayland").client;
const wl = wayland.wl;
const xdg = wayland.xdg;
const zwp = wayland.zwp;

pub const Params = struct {
  context: *Context,
  resolution: @Vector(2, i32),
};

const DmabufFormatTable = packed struct {
  format: i16,
  modifiers: i16,
  padding: i4,
  modifier: u64,
};

const vtable = View.VTable {
  .get_resolution = (struct {
    fn callback(_view: *anyopaque) @Vector(2, i32) {
      const view = View.Type.fromOpaque(_view);
      const self = Type.fromOpaque(view.type.parent.?.getValue());
      return self.fb.base.getResolution();
    }
  }).callback,
  .get_position = (struct {
    fn callback(_view: *anyopaque) @Vector(2, i32) {
      const view = View.Type.fromOpaque(_view);
      const self = Type.fromOpaque(view.type.parent.?.getValue());
      _ = self;
      return .{ 0, 0 };
    }
  }).callback,
  .get_scale = (struct {
    fn callback(_view: *anyopaque) f32 {
      const view = View.Type.fromOpaque(_view);
      const self = Type.fromOpaque(view.type.parent.?.getValue());
      _ = self;
      return 1.0;
    }
  }).callback,
};

fn frameListener(_: *wl.Callback, event: wl.Callback.Event, self: *Self) void {
  _ = event;

  self.render() catch |err| {
    std.debug.print("Failed to render: {s}\n", .{ @errorName(err) });
    std.debug.dumpStackTrace(@errorReturnTrace().?.*);
    return;
  };
}

fn xdgSurfaceListener(_: *xdg.Surface, event: xdg.Surface.Event, self: *Self) void {
  switch (event) {
    .configure => |configure| {
      self.xdg_surface.ackConfigure(configure.serial);
      self.surface.commit();
    },
  }
}

fn xdgToplevelListener(_: *xdg.Toplevel, event: xdg.Toplevel.Event, self: *Self) void {
  switch (event) {
    .configure => |configure| {
      if ((configure.width != self.fb.resolution[0] or configure.height != self.fb.resolution[1]) and configure.width > 0 and configure.height > 0) {
        const fb = FrameBuffer.new(.{
          .client = self.getClient(),
          .resolution = .{ configure.width, configure.height },
          .depth = 4,
          .format = .xrgb8888,
        }, null, self.type.allocator) catch return;

        const old_fb = self.fb;
        self.fb = fb;

        self.subrenderer.toBase().updateFrameBuffer(&self.fb.base) catch |err| {
          std.debug.print("Failed to update framebuffer: {s}\n", .{ @errorName(err) });
          std.debug.dumpStackTrace(@errorReturnTrace().?.*);

          self.fb = old_fb;
          return;
        };

        const client = self.getClient();
        const runtime = client.getRuntime();

        if (runtime.engine != null) {
          self.base_view.notifyMetrics(runtime) catch |err| {
            std.debug.print("Failed to notify the metrics: {s}\n", .{ @errorName(err) });
            std.debug.dumpStackTrace(@errorReturnTrace().?.*);
          };
        }

        self.surface.attach(self.fb.wl_buffer, 0, 0);
        self.surface.commit();
        old_fb.unref();
      }
    },
    .close => {
      self.getClient().getRuntime().loop.stop();
    }
  }
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    const client = @fieldParentPtr(Client, "base_client", @fieldParentPtr(BaseClient, "context", params.context));

    self.* = .{
      .type = t,
      .base_view = undefined,
      .surface = try client.compositor.?.createSurface(),
      .xdg_surface = try client.wm_base.?.getXdgSurface(self.surface),
      .xdg_toplevel = try self.xdg_surface.getToplevel(),
      .fb = try FrameBuffer.new(.{
        .client = client,
        .resolution = params.resolution,
        .depth = 4,
        .format = .argb8888,
      }, null, t.allocator),
      .subrenderer = try client.base_client.context.renderer.toBase().createSubrenderer(params.resolution),
      .frame_callback = null,
    };

    _ = try View.init(&self.base_view, .{
      .context = params.context,
      .vtable = &vtable,
    }, self, self.type.allocator);

    self.xdg_surface.setListener(*Self, xdgSurfaceListener, self);
    self.xdg_toplevel.setListener(*Self, xdgToplevelListener, self);
    self.surface.commit();

    if (client.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    self.surface.attach(self.fb.wl_buffer, 0, 0);
    self.surface.commit();

    if (client.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    try self.render();
    if (client.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_view = undefined,
      .surface = self.surface,
      .xdg_surface = self.xdg_surface,
      .xdg_toplevel = self.xdg_toplevel,
      .egl_window = self.egl_window,
      .fb = try self.fb.ref(t.allocator),
      .subrenderer = try self.subrenderer.ref(t.allocator),
      .frame_callback = self.frame_callback,
    };

    _ = try self.base_view.type.refInit(&dest.base_view, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base_view.unref();
    self.fb.unref();
    self.subrenderer.unref();
  }

  pub fn destroy(self: *Self) void {
    self.xdg_toplevel.destroy();
    self.xdg_surface.destroy();
    self.surface.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_view: View,
surface: *wl.Surface,
xdg_surface: *xdg.Surface,
xdg_toplevel: *xdg.Toplevel,
fb: *FrameBuffer,
subrenderer: graphics.subrenderer.Subrenderer,
frame_callback: ?*wl.Callback,

pub usingnamespace Type.Impl;

pub fn getClient(self: *Self) *Client {
  return @fieldParentPtr(Client, "base_client", @fieldParentPtr(BaseClient, "context", self.base_view.context));
}

pub fn render(self: *Self) !void {
  if (self.frame_callback) |cb| {
    cb.destroy();
    self.frame_callback = null;
  }

  const res = self.fb.base.getResolution();
  self.surface.damage(0, 0, res[0], res[1]);

  try self.subrenderer.toBase().render();

  const cb = try self.surface.frame();
  cb.setListener(*Self, frameListener, self);
  self.frame_callback = cb;

  self.surface.commit();
}
