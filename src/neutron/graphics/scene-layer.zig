const std = @import("std");
const elemental = @import("../elemental.zig");
const flutter = @import("../flutter.zig");
const Renderer = @import("renderer.zig").Renderer;
const Self = @This();

pub const Kind = enum {
  platform,
  backing_store,
};

pub const VTable = struct {
  render: ?*const fn (self: *anyopaque, renderer: Renderer) anyerror!void = null,
};

pub const Params = struct {
  vtable: ?*const VTable,
  value: *const flutter.c.FlutterLayer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .value = params.value.*,
      .backing_store = if (params.value.type == flutter.c.kFlutterLayerContentTypeBackingStore) params.value.unnamed_0.backing_store.* else null,
      .platform_view = if (params.value.type == flutter.c.kFlutterLayerContentTypePlatformView) params.value.unnamed_0.platform_view.* else null,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .value = self.value,
      .backing_store = self.backing_store,
      .platform_view = self.platform_view,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: ?*const VTable,
value: flutter.c.FlutterLayer,
backing_store: ?flutter.c.FlutterBackingStore,
platform_view: ?flutter.c.FlutterPlatformView,

pub usingnamespace Type.Impl;

pub fn render(self: *Self, renderer: Renderer) !void {
  if (self.vtable) |vtable| {
    if (vtable.render) |_render| {
      return _render(self.type.toOpaque(), renderer);
    }
  }
}

pub fn getKind(self: *Self) Kind {
  return if (self.value.type == flutter.c.kFlutterLayerContentTypeBackingStore) .backing_store else .platform;
}
