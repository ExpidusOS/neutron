const std = @import("std");
const Context = @import("context.zig");
const elemental = @import("../elemental.zig");
const Output = @This();

// Implementation specific functions
pub const VTable = struct {};

// Instance creation parameters
pub const Params = struct {
  vtable: *const VTable,
  context: *Context,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(Output) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Output, TypeInfo);

/// Implementation specific functions
vtable: *const VTable,
context: *Context,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Output {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  _ = allocator;
  return .{
    .vtable = params.vtable,
    .context = params.context.ref(),
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*Output, @alignCast(@alignOf(Output), _self));
  self.context.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Output, @alignCast(@alignOf(Output), _self));
  const dest = @ptrCast(*Output, @alignCast(@alignOf(Output), _dest));

  dest.vtable = self.vtable;
  dest.context = self.context.ref();
}

/// Creates a new instance of the DisplayKit context
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Output {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *Output) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *Output) *Output {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *Output) void {
  return self.getType().unref();
}
