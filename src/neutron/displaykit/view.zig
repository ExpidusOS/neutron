const std = @import("std");
const elemental = @import("../elemental.zig");
const Context = @import("context.zig");
const View = @This();

// Implementation specific functions
pub const VTable = struct {};

// Instance creation parameters
pub const Params = struct {
  vtable: *const VTable,
  context: *Context,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(View, Params, TypeInfo);

/// Implementation specific functions
vtable: *const VTable,
context: *Context,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !*anyopaque {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  _ = allocator;
  return &(View {
    .vtable = params.vtable,
    .context = params.context.ref(),
  });
}

fn impl_destroy(_self: *anyopaque) !void {
  const self = @ptrCast(*View, @alignCast(@alignOf(View), _self));

  self.context.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*View, @alignCast(@alignOf(View), _self));
  const dest = @ptrCast(*View, @alignCast(@alignOf(View), _dest));

  dest.vtable = self.vtable;
}

/// Creates a new instance of the DisplayKit context
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*View {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.new(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *View) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *View) *View {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *View) void {
  return self.getType().unref();
}
