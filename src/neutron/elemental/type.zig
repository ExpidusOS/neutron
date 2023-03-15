const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;

/// Define type information
pub fn TypeInfo(
  /// Instance type
  comptime T: type,
  /// Parameter type
  comptime P: type
) type {
  return struct {
    /// Initialize method for type
    init: fn (params: P, allocator: Allocator) anyerror!T,

    /// Constructor method
    construct: ?fn (self: *T, params: P) anyerror!void,

    /// Destroy method
    destroy: ?fn (self: *T) void,

    /// Duplication method
    dupe: fn (self: *T, dest: *T) anyerror!void,
  };
}

/// Define a new type
pub fn Type(
  /// Instance type
  comptime T: type,
  /// Parameter type
  comptime P: type,
  /// Type information
  comptime info: TypeInfo(T, P)
) type {
  return struct {
    const Self = @This();

    /// Type information used to create this type
    pub const type_info = info;

    allocated: bool,

    /// Memory allocator used for the instance
    allocator: Allocator,

    /// Type information used to create this type
    comptime type_info: TypeInfo(T, P) = type_info,

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
      if (allocator == null) {
        return Self.new(params, std.heap.page_allocator);
      }

      const self = try allocator.?.create(Self);
      self.allocator = allocator.?;
      self.type_info = info;
      self.allocated = true;
      self.instance = try info.init(params, self.allocator);

      if (info.construct != null) {
        try info.construct.?(&self.instance, params);
      }
      return self;
    }

    // Initializes a new type instance rather than allocates one
    pub fn init(
      //// Parameters to pass for creating the instance.
      params: P,
      /// An optional memory allocator to use, defaults to `std.heap.page_allocator` if `null`.
      allocator: ?Allocator
    ) !Self {
      if (allocator == null) {
        return Self.init(params, std.heap.page_allocator);
      }

      const self = Self {
        .allocated = false,
        .allocator = allocator.?,
        .type_info = info,
        .ref_count = 0,
        .ref_lock = .{},
        .instance = try info.init(params, allocator.?),
      };

      if (info.construct != null) {
        try info.construct.?(&self.instance, params);
      }
      return self;
    }

    /// Duplicate the instance
    pub fn dupe(self: *Self) !*Self {
      const dest = try self.allocator.create(Self);
      dest.allocator = self.allocator;
      dest.type_info = self.type_info;
      dest.allocated = true;

      try info.dupe(&self.instance, &dest.instance);
      return dest;
    }

    /// Creates a reference
    pub fn ref(self: *Self) *Self {
      Mutex.lock(&self.ref_lock);
      self.ref_count += 1;
      Mutex.unlock(&self.ref_lock);
      return self;
    }

    /// Decreases the reference count.
    /// Once it hits 0, destroy the instance.
    pub fn unref(self: *Self) void {
      Mutex.lock(&self.ref_lock);

      if (self.ref_count == 0) {
        if (info.destroy != null) {
          info.destroy.?(&self.instance);
        }

        defer {
          if (self.allocated) self.allocator.destroy(self);
        }
      } else {
        self.ref_count -= 1;
      }

      Mutex.unlock(&self.ref_lock);
    }
  };
}
