const std = @import("std");
const elemental = @import("../../../elemental.zig");
const GpuDevice = @import("../../gpu-device.zig");
const DummyGpuDevice = @This();

pub const TypedList = elemental.TypedList(DummyGpuDevice, Params, TypeInfo);

/// Instance creation parameters
pub const Params = struct {
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(DummyGpuDevice) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(DummyGpuDevice, Params, TypeInfo);

gpu_device: GpuDevice.Type,

const vtable = GpuDevice.VTable {
  .get_allocator = impl_get_allocator,
};

fn impl_get_allocator(_self: *anyopaque) std.mem.Allocator {
  const self = @ptrCast(*DummyGpuDevice, @alignCast(@alignOf(DummyGpuDevice), _self));
  return self.getType().allocator;
}

fn impl_init(_: *anyopaque, allocator: std.mem.Allocator) !DummyGpuDevice {
  return .{
    .gpu_device = try GpuDevice.init(.{
      .vtable = &vtable,
    }, allocator),
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*DummyGpuDevice, @alignCast(@alignOf(DummyGpuDevice), _self));
  self.gpu_device.unref();
}

fn impl_dupe(_: *anyopaque, _dest: *anyopaque) !void {
  const dest = @ptrCast(*DummyGpuDevice, @alignCast(@alignOf(DummyGpuDevice), _dest));

  dest.gpu_device = try GpuDevice.init(.{
    .vtable = &vtable,
  }, dest.getType().allocator);
}

pub fn getAll(allocator: ?std.mem.Allocator) !*TypedList {
  if (allocator == null) {
    return try getAll(std.heap.page_allocator);
  }

  return try TypedList.new(.{
    .list = null,
  }, allocator.?);
}

/// Creates a new instance of a Linux GPU device
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*DummyGpuDevice {
  return &(try Type.new(params, allocator)).instance;
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *DummyGpuDevice) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *DummyGpuDevice) *DummyGpuDevice {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *DummyGpuDevice) void {
  return self.getType().unref();
}

pub fn getAllocator(self: *DummyGpuDevice) std.mem.Allocator {
  return self.getType().allocator;
}
