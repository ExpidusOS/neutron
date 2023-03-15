const std = @import("std");
const config = @import("neutron-config");
const elemental = @import("../../elemental.zig");
const Context = @import("../context.zig");
const Compositor = @import("../compositor.zig");
const Output = @import("../output.zig");
const View = @import("../view.zig");
const WlrootsCompositor = @This();

comptime {
  if (!config.use_wlroots) @compileError("Wlroots is not enabled, failed to import");
}

/// Instance creation parameters
pub const Params = struct {};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(WlrootsCompositor) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(WlrootsCompositor, Params, TypeInfo);

/// DisplayKit compositor instance
compositor: Compositor.Type,
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
  const self = @fieldParentPtr(WlrootsCompositor, "compositor", compositor.getType());

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
  const self = @fieldParentPtr(WlrootsCompositor, "compositor", compositor.getType());

  const values = try self.getType().allocator.alloc(*View, self.views.list.items.len);

  var i: u32 = 0;
  for (self.views.list.items) |value| {
    values[i] = &(value.ref()).instance;
    i += 1;
  }
  return values;
}

fn impl_init(params: *const anyopaque, allocator: std.mem.Allocator) !WlrootsCompositor {
  _ = params;
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
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*WlrootsCompositor, @alignCast(@alignOf(WlrootsCompositor), _self));

  self.compositor.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*WlrootsCompositor, @alignCast(@alignOf(WlrootsCompositor), _self));
  const dest = @ptrCast(*WlrootsCompositor, @alignCast(@alignOf(WlrootsCompositor), _dest));

  dest.compositor = try Compositor.init(.{
    .vtable = self.compositor.instance.vtable,
  }, self.getType().allocator);
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*WlrootsCompositor {
  return &(try Type.new(params, allocator)).instance;
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *WlrootsCompositor) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *WlrootsCompositor) *WlrootsCompositor {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *WlrootsCompositor) void {
  return self.getType().unref();
}
