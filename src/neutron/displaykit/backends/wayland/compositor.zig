const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Context = @import("../../context.zig");
const Compositor = @import("../../compositor.zig");
const Output = @import("../../output.zig");
const View = @import("../../view.zig");
const WaylandCompositor = @This();
const wl = @import("wayland").server.wl;
const libdrm = @import("libdrm");

/// Instance creation parameters
pub const Params = struct {
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(WaylandCompositor) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(WaylandCompositor, Params, TypeInfo);

/// DisplayKit compositor instance
compositor: Compositor.Type,

/// Wayland server instance
wl_server: *wl.Server,

outputs: *elemental.TypedList(Output, Output.Params, Output.TypeInfo),
views: *elemental.TypedList(View, View.Params, View.TypeInfo),

const vtable = Compositor.VTable {
  .context = &.{
    .list_outputs = impl_list_outputs,
    .list_views = impl_list_views,
  },
};

fn impl_list_outputs(ctx: *anyopaque) ![]*Output {
  const compositor = @fieldParentPtr(Compositor, "context", @ptrCast(*Context, @alignCast(@alignOf(Context), ctx)).getType());
  const self = @fieldParentPtr(WaylandCompositor, "compositor", compositor.getType());

  const values = try self.getType().allocator.alloc(*Output, self.outputs.list.items.len);

  var i: u32 = 0;
  for (self.outputs.list.items) |value| {
    values[i] = &(value.ref()).instance;
    i += 1;
  }
  return values;
}

fn impl_list_views(ctx: *anyopaque) ![]*View {
  const compositor = @fieldParentPtr(Compositor, "context", @ptrCast(*Context, @alignCast(@alignOf(Context), ctx)).getType());
  const self = @fieldParentPtr(WaylandCompositor, "compositor", compositor.getType());

  const values = try self.getType().allocator.alloc(*View, self.views.list.items.len);

  var i: u32 = 0;
  for (self.views.list.items) |value| {
    values[i] = &(value.ref()).instance;
    i += 1;
  }
  return values;
}

fn impl_init(_: *anyopaque, allocator: std.mem.Allocator) !WaylandCompositor {
  return .{
    .outputs = try elemental.TypedList(Output, Output.Params, Output.TypeInfo).new(.{
      .list = null,
    }, allocator),
    .views = try elemental.TypedList(View, View.Params, View.TypeInfo).new(.{
      .list = null,
    }, allocator),
    .compositor = try Compositor.init(.{
      .vtable = &vtable,
    }, allocator),
    .wl_server = try wl.Server.create(),
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*WaylandCompositor, @alignCast(@alignOf(WaylandCompositor), _self));

  self.compositor.unref();
  self.wl_server.destroyClients();
  self.wl_server.destroy();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*WaylandCompositor, @alignCast(@alignOf(WaylandCompositor), _self));
  const dest = @ptrCast(*WaylandCompositor, @alignCast(@alignOf(WaylandCompositor), _dest));

  dest.compositor = try Compositor.init(.{
    .vtable = self.compositor.instance.vtable,
  }, self.getType().allocator);
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*WaylandCompositor {
  return &(try Type.new(params, allocator)).instance;
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *WaylandCompositor) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *WaylandCompositor) *WaylandCompositor {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *WaylandCompositor) void {
  return self.getType().unref();
}
