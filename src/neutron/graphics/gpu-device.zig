const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

/// Virtual function table
pub const VTable = struct {
  /// Method for getting an std allocator for the GPU's memory
  get_allocator: *const fn (self: *anyopaque) std.mem.Allocator,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .vtable = self.vtable,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return .{
    .type = Type.init(parent, allocator),
    .vtable = params.vtable,
  };
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self) !*Self {
  return self.type.refNew();
}

pub inline fn unref(self: *Self) !void {
  return self.type.unref();
}

/// Get the VRAM allocator for the GPU
pub inline fn getAllocator(self: *Self) std.mem.Allocator {
  return self.vtable.get_allocator(@ptrCast(*anyopaque, @alignCast(@alignOf(Self), self)));
}
