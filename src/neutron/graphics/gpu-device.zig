const std = @import("std");
const elemental = @import("../elemental.zig");
const GpuDevice = @This();

/// Implementation specific functions
pub const VTable = struct {
  get_allocator: *const fn (self: *anyopaque) std.mem.Allocator,
};

/// Instance creation parameters
pub const Params = struct {
  vtable: *const VTable
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(GpuDevice) {
  .init = impl_init,
  .construct = null,
  .destroy = null,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(GpuDevice, Params, TypeInfo);

vtable: *const VTable,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !GpuDevice {
  _ = allocator;
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  return .{
    .vtable = params.vtable,
  };
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*GpuDevice, @alignCast(@alignOf(GpuDevice), _self));
  const dest = @ptrCast(*GpuDevice, @alignCast(@alignOf(GpuDevice), _dest));
  dest.vtable = self.vtable;
}

/// Creates a new instance of the GPU device
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*GpuDevice {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *GpuDevice) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *GpuDevice) *GpuDevice {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *GpuDevice) void {
  return self.getType().unref();
}

/// Get a Zig allocator for allocating from GPU memory (aka. VRAM)
pub fn getAllocator(self: *GpuDevice) std.mem.Allocator {
  return self.vtable.get_allocator(self);
}
