const std = @import("std");
const xev = @import("xev");
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

const vtable = View.VTable {};

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
          .format = .argb8888,
        }, null, self.type.allocator) catch return;

        const old_fb = self.fb;
        self.fb = fb;

        self.subrenderer.toBase().updateFrameBuffer(&self.fb.base) catch |err| {
          std.debug.print("Failed to update framebuffer: {s}\n", .{ @errorName(err) });
          std.debug.dumpStackTrace(@errorReturnTrace().?.*);

          self.fb = old_fb;
          return;
        };

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
      .completion = undefined,
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

    client.getRuntime().loop.timer(&self.completion, 500, self, (struct {
      fn callback(ud: ?*anyopaque, loop: *xev.Loop, completion: *xev.Completion, res: xev.Result) xev.CallbackAction {
        const view = Type.fromOpaque(ud.?);

        _ = loop;
        _ = completion;
        _ = res;

        view.subrenderer.toBase().updateFrameBuffer(&view.fb.base) catch |err| {
          std.debug.print("Failed to update framebuffer: {s}\n", .{ @errorName(err) });
          std.debug.dumpStackTrace(@errorReturnTrace().?.*);
          return .rearm;
        };

        view.subrenderer.toBase().render() catch |err| {
          std.debug.print("Failed to render: {s}\n", .{ @errorName(err) });
          std.debug.dumpStackTrace(@errorReturnTrace().?.*);
          return .rearm;
        };

        view.surface.commit();
        return .rearm;
      }
    }).callback);
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
      .completion = self.completion,
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
completion: xev.Completion,

pub usingnamespace Type.Impl;

pub fn getClient(self: *Self) *Client {
  return @fieldParentPtr(Client, "base_client", @fieldParentPtr(BaseClient, "context", self.base_view.context));
}
