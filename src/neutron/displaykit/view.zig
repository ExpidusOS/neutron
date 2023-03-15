const std = @import("std");
const Context = @import("context.zig");
const elemental = @import("../elemental.zig");

fn impl_init(params: View.Params, allocator: std.mem.Allocator) !View {
  _ = allocator;
  return .{
    .vtable = params.vtable,
    .context = params.context.ref(),
  };
}

fn destroy(self: *View) void {
  self.context.unref();
}

fn dupe(self: *View, dest: *View) !void {
  dest.vtable = self.vtable;
}

// Base type for views
pub const View = struct {
  // Implementation specific functions
  pub const VTable = struct {};

  // Instance creation parameters
  pub const Params = struct {
    vtable: VTable,
    context: *Context,
  };

  /// Neutron's Elemental type information
  pub const TypeInfo = elemental.TypeInfo(View, Params) {
    .init = impl_init,
    .construct = null,
    .destroy = destroy,
    .dupe = dupe,
  };

  /// Neutron's Elemental type definition
  pub const Type = elemental.Type(View, Params, TypeInfo);

  /// Implementation specific functions
  vtable: VTable,
  context: *Context,

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
};
