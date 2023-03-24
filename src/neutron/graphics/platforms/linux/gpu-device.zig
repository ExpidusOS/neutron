const std = @import("std");
const elemental = @import("../../../elemental.zig");
const GpuDevice = @import("../../gpu-device.zig");
const libdrm = @import("libdrm");
const LinuxGpuDevice = @This();

pub const TypedList = elemental.TypedList(LinuxGpuDevice, Params, TypeInfo);

/// Instance creation parameters
pub const Params = struct {
  libdrm_node: *libdrm.DeviceNode,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(LinuxGpuDevice) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(LinuxGpuDevice, Params, TypeInfo);

gpu_device: GpuDevice.Type,
libdrm_node: *libdrm.DeviceNode,

const vtable = GpuDevice.VTable {
  .get_allocator = impl_get_allocator,
};

fn impl_get_allocator(_self: *anyopaque) std.mem.Allocator {
  const self = @ptrCast(*LinuxGpuDevice, @alignCast(@alignOf(LinuxGpuDevice), _self));
  return self.libdrm_node.getAllocator();
}

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !LinuxGpuDevice {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  var self = LinuxGpuDevice{
    .gpu_device = try GpuDevice.init(.{
      .vtable = &vtable,
    }, allocator),
    .libdrm_node = try libdrm.DeviceNode.init(allocator, params.libdrm_node.path),
  };

  const alloc = self.libdrm_node.getAllocator();
  const value = try alloc.dupe(u8, "Hello, world");
  defer alloc.free(value);
  return self;
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*LinuxGpuDevice, @alignCast(@alignOf(LinuxGpuDevice), _self));
  self.gpu_device.unref();
  self.libdrm_node.deinit();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*LinuxGpuDevice, @alignCast(@alignOf(LinuxGpuDevice), _self));
  const dest = @ptrCast(*LinuxGpuDevice, @alignCast(@alignOf(LinuxGpuDevice), _dest));

  dest.gpu_device = try GpuDevice.init(.{
    .vtable = &vtable,
  }, dest.getType().allocator);
  dest.libdrm_node = try libdrm.DeviceNode.init(dest.getType().allocator, self.libdrm_node.path);
}

pub fn getAll(allocator: ?std.mem.Allocator) !*TypedList {
  if (allocator == null) {
    return try getAll(std.heap.page_allocator);
  }

  var libdrm_devices = try libdrm.getDevices2Alloc(allocator.?, 0);
  defer libdrm.freeDevices(allocator.?, libdrm_devices);

  const devices = try TypedList.new(.{
    .list = null,
  }, allocator.?);

  for (libdrm_devices) |device| {
    var nodes = try device.getNodes();
    for (nodes) |node| {
      if (node == null) continue;
      defer node.?.deinit();

      const dev = try LinuxGpuDevice.new(.{
        .libdrm_node = node.?,
      }, allocator.?);
      defer dev.unref();
      try devices.append(dev.getType());
    }
  }
  return devices;
}

/// Creates a new instance of a Linux GPU device
pub fn new(params: Params, allocator: ?std.mem.Allocator) !*LinuxGpuDevice {
  return &(try Type.new(params, allocator)).instance;
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *LinuxGpuDevice) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *LinuxGpuDevice) *LinuxGpuDevice {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *LinuxGpuDevice) void {
  return self.getType().unref();
}

pub fn getAllocator(self: *LinuxGpuDevice) std.mem.Allocator {
  return self.libdrm_node.getAllocator();
}
