const std = @import("std");
const Context = @import("context.zig").Context;
const elemental = @import("../elemental.zig");

fn impl_init(params: Output.Params, allocator: std.mem.Allocator) !Output {
  _ = allocator;
  return .{
    .vtable = params.vtable,
    .context = params.context.ref(),
  };
}

fn impl_destroy(self: *Output) void {
  self.context.unref();
}

fn dupe(self: *Output, dest: *Output) !void {
  dest.vtable = self.vtable;
  dest.context = self.context.ref();
}

// Base type for display outputs
pub const Output = struct {
  // Implementation specific functions
  pub const VTable = struct {};

  // Instance creation parameters
  pub const Params = struct {
    vtable: *const VTable,
    context: *Context,
  };

  /// Neutron's Elemental type information
  pub const TypeInfo = elemental.TypeInfo(Output, Params) {
    .init = impl_init,
    .construct = null,
    .destroy = impl_destroy,
    .dupe = dupe,
  };

  /// Neutron's Elemental type definition
  pub const Type = elemental.Type(Output, Params, TypeInfo);

  /// Implementation specific functions
  vtable: *const VTable,
  context: *Context,

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
};
