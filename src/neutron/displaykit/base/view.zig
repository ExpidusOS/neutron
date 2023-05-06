const std = @import("std");
const elemental = @import("../../elemental.zig");
const flutter = @import("../../flutter.zig");
const Runtime = @import("../../runtime/runtime.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  get_resolution: *const fn (self: *anyopaque) @Vector(2, i32),
  get_position: *const fn (self: *anyopaque) @Vector(2, i32),
  get_scale: *const fn (self: *anyopaque) f32,
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
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = self.context,
    };
  }

  pub fn unref(self: *Self) void {
    _ = self;
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: *Context,

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

pub fn notifyMetrics(self: *Self, runtime: *Runtime) !void {
  if (self.context._type != .client) return error.InvalidContext;

  const res = self.getResolution();
  const pos = self.getPosition();
  const scale = self.getScale();

  const event = flutter.c.FlutterWindowMetricsEvent {
    .struct_size = @sizeOf(flutter.c.FlutterWindowMetricsEvent),
    .width = @intCast(usize, res[0]),
    .height = @intCast(usize, res[1]),
    .pixel_ratio = scale,
    .left = @intCast(usize, pos[0]),
    .top = @intCast(usize, pos[1]),
    .physical_view_inset_top = 0,
    .physical_view_inset_right = 0,
    .physical_view_inset_bottom = 0,
    .physical_view_inset_left = 0,
  };

  const result = runtime.proc_table.SendWindowMetricsEvent.?(runtime.engine, &event);
  if (result != flutter.c.kSuccess) return error.EngineFail;
}
