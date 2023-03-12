const std = @import("std");
const elemental = @import("../elemental.zig");

fn construct(self: *Context, params: Context.Params) void {
  self.vtable = params.vtable;
}

fn destroy(self: *Context) void {
  _ = self;
}

fn dupe(self: *Context, dest: *Context) void {
  dest.vtable = self.vtable;
}

/// Base type for compositors and clients
pub const Context = struct {
  /// Implementation specific functions
  pub const VTable = struct {};

  /// Instance creation parameters
  pub const Params = struct {
    vtable: VTable
  };

  /// Neutron's Elemental type information
  pub const TypeInfo = elemental.TypeInfo(Context, Params) {
    .construct = construct,
    .destroy = destroy,
    .dupe = dupe,
  };

  /// Neutron's Elemental type definition
  pub const Type = elemental.Type(Context, Params, TypeInfo);

  /// Implementation specific functions
  vtable: VTable,

  /// Creates a new instance of the DisplayKit context
  pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Context {
    return &(try Type.new(params, allocator)).instance;
  }

  /// Gets the Elemental type definition instance for this instance
  pub fn getType(self: *Context) *Type {
    return @fieldParentPtr(Type, "instance", self);
  }

  /// Increases the reference count and return the instance
  pub fn ref(self: *Context) *Context {
    return &(self.getType().ref().instance);
  }

  /// Decreases the reference count and free it if the counter is 0
  pub fn unref(self: *Context) void {
    return self.getType().unref();
  }
};
