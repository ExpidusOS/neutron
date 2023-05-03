const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const Self = @This();
const Base = @import("base.zig");
const Context = @import("../context.zig");

pub const EventKind = enum {
  add,
  remove,

  pub fn toFlutter(self: EventKind) flutter.c.FlutterPointerPhase {
    return switch (self) {
      .add => flutter.c.kAdd,
      .remove => flutter.c.kRemove,
    };
  }
};

pub const Params = struct {
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base = try Base.init(&self.base, .{
        .context = params.context,
      }, self, self.type.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = undefined,
    };

    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,

pub usingnamespace Type.Impl;

pub fn notify(self: *Self, kind: EventKind, time: usize) flutter.c.FlutterPointerEvent {
  _ = self;

  return .{
    .struct_size = @sizeOf(flutter.c.FlutterPointerEvent),
    .timestamp = time,
    .phase = kind.toFlutter(),

    // TODO: implement this from vtable
    .x = 0,
    .y = 0,
    .device = 0,
    .signal_kind = flutter.c.kFlutterPointerSignalKindNone,

    // TODO: implement this from vtable
    .scroll_delta_x = 0,
    .scroll_delta_y = 0,

    .device_kind = flutter.c.kFlutterPointerDeviceKindTouch,

    // TODO: implement this from vtable
    .buttons = 0,
    .pan_x = 0,
    .pan_y = 0,
    .scale = 1.0,
    .rotation = 0.0,
  };
}
