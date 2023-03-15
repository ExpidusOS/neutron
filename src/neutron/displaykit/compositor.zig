const std = @import("std");
const elemental = @import("../elemental.zig");
const Context = @import("context.zig");
const Compositor = @This();

/// Implementation specific functions
pub const VTable = struct {
  /// Implementation specific functions for the context
  context: *const Context.VTable,
};

/// Instance creation parameters
pub const Params = struct {
  vtable: *const VTable
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(Compositor) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Compositor, Params, TypeInfo);

vtable: *const VTable,
context: Context.Type,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Compositor {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  return Compositor {
    .vtable = params.vtable,
    .context = try Context.init(.{
      .vtable = params.vtable.context,
    }, allocator),
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*Compositor, @alignCast(@alignOf(Compositor), _self));

  self.context.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Compositor, @alignCast(@alignOf(Compositor), _self));
  const dest = @ptrCast(*Compositor, @alignCast(@alignOf(Compositor), _dest));

  dest.vtable = self.vtable;
  dest.context = try Context.init(.{
    .vtable = self.vtable.context,
  }, self.getType().allocator);
}

/// Creates a new instance of the DisplayKit compositor
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Compositor {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *Compositor) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *Compositor) *Context {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *Compositor) void {
  return self.getType().unref();
}

pub fn dupe(self: *Compositor) !*Compositor {
  return &(try self.getType().dupe()).instance;
}
