const std = @import("std");
const elemental = @import("../elemental.zig");
const Context = @import("context.zig").Context;

fn construct(self: *Client, params: Client.Params) !void {
  self.vtable = params.vtable;
  self.context = try Context.new(params.vtable.context, self.getType().allocator);
}

fn destroy(self: *Client) void {
  self.context.unref();
}

fn dupe(self: *Client, dest: *Client) void {
  dest.vtable = self.vtable;
  dest.context = self.context.dupe();
}

/// Base type for clients
pub const Client = struct {
  const Self = @This();

  /// Implementation specific functions
  pub const VTable = struct {
    /// Implementation specific functions for the context
    context: Context.VTable,
  };

  /// Instance creation parameters
  pub const Params = struct {
    vtable: VTable
  };

  /// Neutron's Elemental type information
  pub const TypeInfo = elemental.TypeInfo(Client, Params) {
    .construct = construct,
    .destroy = destroy,
    .dupe = dupe,
  };

  /// Neutron's Elemental type definition
  pub const Type = elemental.Type(Client, Params, TypeInfo);

  vtable: VTable,
  context: *Context,

  /// Creates a new instance of the DisplayKit client
  pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Context {
    return &(try Type.new(params, allocator)).instance;
  }

  /// Gets the Elemental type definition instance for this instance
  pub fn getType(self: *Client) *Type {
    return @fieldParentPtr(Type, "instance", self);
  }

  /// Increases the reference count and return the instance
  pub fn ref(self: *Client) *Context {
    return &(self.getType().ref().instance);
  }

  /// Decreases the reference count and free it if the counter is 0
  pub fn unref(self: *Context) void {
    return self.getType().unref();
  }
};
