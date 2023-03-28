const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;
const formatter = @import("formatter.zig");

/// Define type information
pub const TypeInfo = struct {
  /// Initialize method for type
  init: *const fn (params: *anyopaque, allocator: Allocator) anyerror!*anyopaque,

  /// Constructor method
  construct: ?*const fn (self: *anyopaque, params: *anyopaque) anyerror!void = null,

  /// Destroy method
  destroy: ?*const fn (self: *anyopaque) anyerror!void = null,

  /// Duplication method
  dupe: *const fn (self: *anyopaque, dest: *anyopaque) anyerror!void,
};

/// Define a new type
pub fn Type(
  /// Instance type
  comptime T: type,
  /// Parameter type
  comptime P: type,
  /// Type information
  comptime type_info: TypeInfo
) type {
  return struct {
    const Self = @This();

    pub const Info = type_info;

    allocated: bool,

    type_info: TypeInfo,

    parent: ?*OpaqueType,

    /// Memory allocator used for the instance
    allocator: Allocator,

    /// Number of references which have been created
    ref_count: i32,

    /// Mutex lock for referencing
    ref_lock: Mutex,

    /// Instance data for the type
    instance: T,

    /// Create a new type instance
    pub fn new(
      //// Parameters to pass for creating the instance.
      params: P,
      /// An optional memory allocator to use, defaults to `std.heap.page_allocator` if `null`.
      allocator: ?Allocator
    ) !*Self {
      if (allocator) |alloc| {
        const self = try alloc.create(Self);
        errdefer alloc.destroy(self);

        self.* = try Self.init(params, allocator);
        self.allocated = true;
        return self;
      }
      return Self.new(params, std.heap.page_allocator);
    }

    // Initializes a new type instance rather than allocates one
    pub fn init(
      //// Parameters to pass for creating the instance.
      params: P,
      /// An optional memory allocator to use, defaults to `std.heap.page_allocator` if `null`.
      allocator: ?Allocator
    ) !Self {
      if (allocator) |alloc| {
        const opaque_instance_ptr = try type_info.init(@ptrCast(*anyopaque, @alignCast(@alignOf(*P), @constCast(&params))), allocator.?);
        const instance_ptr = @ptrCast(*T, @alignCast(@alignOf(*T), opaque_instance_ptr));

        const self = Self {
          .allocated = false,
          .allocator = alloc,
          .parent = null,
          .ref_count = 0,
          .ref_lock = .{},
          .type_info = type_info,
          .instance = instance_ptr.*,
        };

        if (type_info.construct) |construct| {
          try construct(@ptrCast(*anyopaque, @alignCast(@alignOf(*T), @constCast(&self.instance))), @ptrCast(*anyopaque, @alignCast(@alignOf(*P), @constCast(&params))));
        }
        return self;
      }
      return Self.init(params, std.heap.page_allocator);
    }

    pub fn toOpaque(self: *Self) *OpaqueType {
      return @ptrCast(*OpaqueType, @alignCast(@alignOf(*OpaqueType), self));
    }

    pub fn getTop(self: *Self) *OpaqueType {
      var parent = self.parent;
      while (parent) |value| : (parent = @field(value, "parent")) {
        if (@field(value, "parent") == null) return value;
      }

      return self.toOpaque();
    }

    /// Duplicate the instance
    pub fn dupe(self: *Self, allocator: ?Allocator) !*Self {
      if (allocator) |alloc| {
        const dest = try self.allocator.create(Self);
        dest.allocator = alloc;
        dest.allocated = true;

        try type_info.dupe(&self.instance, &dest.instance);
        return dest;
      }

      return self.dupe(self.allocator);
    }

    /// Creates a reference
    pub fn ref(self: *Self) *Self {
      const top = self.getTop();

      Mutex.lock(&top.ref_lock);
      defer Mutex.unlock(&top.ref_lock);
      top.ref_count += 1;
      return self;
    }

    /// Decreases the reference count.
    /// Once it hits 0, destroy the instance.
    pub fn unref(self: *Self) void {
      const top = self.getTop();

      Mutex.lock(&top.ref_lock);
      defer Mutex.unlock(&top.ref_lock);

      if (top.ref_count == 0) {
        if (type_info.destroy) |destroy| {
          destroy(&self.instance) catch @panic("Cannot fail during type destruction");
        }

        defer {
          if (self.allocated) self.allocator.destroy(self);
        }
      } else {
        top.ref_count += 1;
      }
    }
  };
}

pub const OpaqueTypeValue = struct {
  pub fn getType(self: *OpaqueTypeValue) *OpaqueTypeValue {
    return @fieldParentPtr(OpaqueType, "instance", self);
  }

  /// Increases the reference count and return the instance
  pub fn ref(self: *OpaqueTypeValue) *OpaqueTypeValue {
    return &(self.getType().ref().instance);
  }

  /// Decreases the reference count and free it if the counter is 0
  pub fn unref(self: *OpaqueTypeValue) void {
    return self.getType().unref();
  }

  pub fn dupe(self: *OpaqueTypeValue, allocator: ?std.mem.Allocator) *OpaqueTypeValue {
    return &(try self.getType().dupe(allocator)).instance;
  }
};

pub const OpaqueType = Type(OpaqueTypeValue, OpaqueTypeValue, .{
  .init = opaque_impl_init,
  .dupe = opaque_impl_dupe,
});

fn opaque_impl_init(_: *anyopaque, allocator: Allocator) !*anyopaque {
  _ = allocator;
  return @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), @constCast(&(OpaqueTypeValue {}))));
}

fn opaque_impl_dupe(_: *anyopaque, dest: *anyopaque) !void {
  _ = dest;
}
