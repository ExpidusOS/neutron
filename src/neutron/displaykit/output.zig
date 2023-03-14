const std = @import("std");
const Context = @import("context.zig").Context;
const elemental = @import("../elemental.zig");

fn construct(self: *Output, params: Output.Params) void {
  self.vtable = params.vtable;
  self.context = params.context.ref();
}

fn destroy(self: *Output) void {
  self.context.unref();
}

fn dupe(self: *Output, dest: *Output) void {
  dest.vtable = self.vtable;
  dest.context = self.context.ref();
}

// Base type for display outputs
pub const Output = struct {
  // Implementation specific functions
  pub const VTable = struct {};

  // Instance creation parameters
  pub const Params = struct {
    vtable: VTable,
    context: *Context,
  };

  /// Neutron's Elemental type information
  pub const TypeInfo = elemental.TypeInfo(Output, Params) {
    .construct = construct,
    .destroy = destroy,
    .dupe = dupe,
  };

  /// Neutron's Elemental type definition
  pub const Type = elemental.Type(Output, Params, TypeInfo);

  /// Implementation specific functions
  vtable: VTable,
  context: *Context,

  /// Creates a new instance of the DisplayKit context
  pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Output {
    return &(try Type.new(params, allocator)).instance;
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
