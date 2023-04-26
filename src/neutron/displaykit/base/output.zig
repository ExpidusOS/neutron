const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const flutter = @import("../../flutter.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  get_resolution: *const fn (self: *anyopaque) @Vector(2, i32),
  get_position: *const fn (self: *anyopaque) @Vector(2, i32),
  get_scale: *const fn (self: *anyopaque) f32,
  get_physical_size: *const fn (self: *anyopaque) @Vector(2, i32),
  get_refresh_rate: *const fn (self: *anyopaque) i32,
  get_id: *const fn (self: *anyopaque) u32,
};

pub const Params = struct {
  vtable: *const VTable,
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .context = params.context,
      .subrenderer = try params.context.renderer.toBase().createSubrenderer(self.getResolution()),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = self.context,
      .subrenderer = try self.subrenderer.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    // FIXME: segment faults
    // self.subrenderer.unref();
    _ = self;
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: *Context,
subrenderer: graphics.subrenderer.Subrenderer,

pub usingnamespace Type.Impl;

pub fn getResolution(self: *Self) @Vector(2, i32) {
  return self.vtable.get_resolution(self.type.toOpaque());
}

pub fn getPosition(self: *Self) @Vector(2, i32) {
  return self.vtable.get_position(self.type.toOpaque());
}

pub fn getScale(self: *Self) f32 {
  return self.vtable.get_scale(self.type.toOpaque());
}

pub fn getPhysicalSize(self: *Self) @Vector(2, i32) {
  return self.vtable.get_physical_size(self.type.toOpaque());
}

pub fn getRefreshRate(self: *Self) i32 {
  return self.vtable.get_refresh_rate(self.type.toOpaque());
}

pub fn getId(self: *Self) u32 {
  return self.vtable.get_id(self.type.toOpaque());
}

pub fn sendMetrics(self: *Self, runtime: *Runtime) !void {
  if (runtime.engine != null) {
    const res = self.getResolution();
    const pos = self.getPosition();

    const event = flutter.c.FlutterWindowMetricsEvent {
      .struct_size = @sizeOf(flutter.c.FlutterWindowMetricsEvent),
      .width = @intCast(usize, res[0]),
      .height = @intCast(usize, res[1]),
      .pixel_ratio = 1.0 * self.getScale(),
      .left = @intCast(usize, pos[0]),
      .top = @intCast(usize, pos[1]),
      .physical_view_inset_top = 0.0,
      .physical_view_inset_right = 0.0,
      .physical_view_inset_bottom = 0.0,
      .physical_view_inset_left = 0.0,
    };

    const result = runtime.proc_table.SendWindowMetricsEvent.?(runtime.engine, &event);
    if (result != flutter.c.kSuccess) return error.EngineFail;
  }
}
