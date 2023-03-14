const std = @import("std");
const config = @import("neutron-config");
const elemental = @import("../../elemental.zig");
const Context = @import("../context.zig").Context;
const Compositor = @import("../compositor.zig").Compositor;
const Output = @import("../output.zig").Output;
const View = @import("../view.zig").View;

comptime {
  if (!config.use_wlroots) @compileError("Wlroots is not enabled, failed to import");
}

const vtable = Compositor.VTable {
  .context = .{
    .list_outputs = list_outputs,
    .list_views = list_views,
  },
};

fn list_outputs(ctx: *Context) !*elemental.TypedList(Output, Output.Params, Output.TypeInfo) {
  const compositor = @fieldParentPtr(Compositor, "context", ctx.getType());
  const self = @fieldParentPtr(WlrootsCompositor, "compositor", compositor.getType());
  return self.outputs.dupe();
}

fn list_views(ctx: *Context) !*elemental.TypedList(View, View.Params, View.TypeInfo) {
  const compositor = @fieldParentPtr(Compositor, "context", ctx.getType());
  const self = @fieldParentPtr(WlrootsCompositor, "compositor", compositor.getType());
  return self.views.dupe();
}

fn init(params: WlrootsCompositor.Params, allocator: std.mem.Allocator) !WlrootsCompositor {
  _ = params;
  return .{
    .outputs = try elemental.TypedList(Output, Output.Params, Output.TypeInfo).new(.{
      .list = null,
    }, allocator),
    .views = try elemental.TypedList(View, View.Params, View.TypeInfo).new(.{
      .list = null,
    }, allocator),
    .compositor = try Compositor.init(.{
      .vtable = vtable,
    }, allocator),
  };
}

fn construct(self: *WlrootsCompositor, params: WlrootsCompositor.Params) !void {
  _ = params;

  self.outputs = try elemental.TypedList(Output, Output.Params, Output.TypeInfo).new(.{
    .list = null,
  }, self.getType().allocator);

  self.views = try elemental.TypedList(View, View.Params, View.TypeInfo).new(.{
    .list = null,
  }, self.getType().allocator);

  self.compositor = try Compositor.init(.{
    .vtable = vtable,
  }, self.getType().allocator);
}

fn destroy(self: *WlrootsCompositor) void {
  self.compositor.unref();
}

fn impl_dupe(self: *WlrootsCompositor, dest: *WlrootsCompositor) !void {
  dest.compositor = try Compositor.init(.{
    .vtable = self.compositor.instance.vtable,
  }, self.getType().allocator);
}

/// A Wayland compositor implemented using wlroots
pub const WlrootsCompositor = struct {
  /// Instance creation parameters
  pub const Params = struct {};

  /// Neutron's Elemental type information
  pub const TypeInfo = elemental.TypeInfo(WlrootsCompositor, Params) {
    .init = init,
    .construct = construct,
    .destroy = destroy,
    .dupe = impl_dupe,
  };

  /// Neutron's Elemental type definition
  pub const Type = elemental.Type(WlrootsCompositor, Params, TypeInfo);

  /// DisplayKit compositor instance
  compositor: Compositor.Type,
  outputs: *elemental.TypedList(Output, Output.Params, Output.TypeInfo),
  views: *elemental.TypedList(View, View.Params, View.TypeInfo),

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
};
