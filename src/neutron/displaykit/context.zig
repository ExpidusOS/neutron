const std = @import("std");
const elemental = @import("../elemental.zig");
const Output = @import("output.zig");
const View = @import("view.zig");
const Context = @This();

/// Implementation specific functions
pub const VTable = struct {
  list_outputs: *const fn (self: *anyopaque) anyerror!*elemental.TypedList(Output, Output.Params, Output.TypeInfo),
  list_views: *const fn (self: *anyopaque) anyerror!*elemental.TypedList(View, View.Params, View.TypeInfo)
};

/// Instance creation parameters
pub const Params = struct {
  vtable: *const VTable
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(Context, Params) {
  .init = impl_init,
  .construct = null,
  .destroy = null,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Context, Params, TypeInfo);

vtable: *const VTable,

fn impl_init(params: Context.Params, allocator: std.mem.Allocator) !Context {
  _ = allocator;
  return .{
    .vtable = params.vtable,
  };
}

fn impl_dupe(self: *Context, dest: *Context) !void {
  dest.vtable = self.vtable;
}

/// Creates a new instance of the DisplayKit context
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Context {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
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

pub fn dupe(self: *Context) !*Context {
  return &(try self.getType().dupe()).instance;
}

/// Gets an array list of outputs
pub fn listOutputs(self: *Context) !*elemental.TypedList(Output, Output.Params, Output.TypeInfo) {
  return try self.vtable.list_outputs(self);
}

/// Gets an array list of views
pub fn listViews(self: *Context) !*elemental.TypedList(View, View.Params, View.TypeInfo) {
  return try self.vtable.list_views(self);
}
