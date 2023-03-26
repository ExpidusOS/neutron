const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;
const formatter = @import("formatter.zig");

/// Define type information
pub fn TypeInfo(comptime T: type) type {
  return struct {
    /// Initialize method for type
    init: *const fn (params: *anyopaque, allocator: Allocator) anyerror!T,

    /// Constructor method
    construct: ?*const fn (self: *anyopaque, params: *anyopaque) anyerror!void,

    /// Destroy method
    destroy: ?*const fn (self: *anyopaque) void,

    /// Duplication method
    dupe: *const fn (self: *anyopaque, dest: *anyopaque) anyerror!void,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, out_stream: anytype) !void {
      _ = fmt;
      _ = options;

      try std.fmt.format(out_stream,
        \\<name>{s}</name>
        \\<methods>
        \\  <init>0x{x}</init>
        \\  <construct>0x{x}</construct>
        \\  <destroy>0x{x}</destroy>
        \\  <dupe>0x{x}</dupe>
        \\</methods>
      , .{
        @typeName(T),
        @ptrToInt(self.init),
        @ptrToInt(self.construct),
        @ptrToInt(self.destroy),
        @ptrToInt(self.dupe),
      });
    }
  };
}

/// Define a new type
pub fn Type(
  /// Instance type
  comptime T: type,
  /// Parameter type
  comptime P: type,
  /// Type information
  comptime info: TypeInfo(T)
) type {
  return struct {
    const Self = @This();

    pub const Info = info;

    allocated: bool,

    type_info: TypeInfo(T),

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
      if (allocator == null) {
        return Self.new(params, std.heap.page_allocator);
      }

      const self = try allocator.?.create(Self);
      self.* = try Self.init(params, allocator);
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
        .ref_count = 0,
        .ref_lock = .{},
        .type_info = info,
        .instance = try info.init(@ptrCast(*anyopaque, @alignCast(@alignOf(*P), @constCast(&params))), allocator.?),
      };

      if (info.construct != null) {
        try info.construct.?(@ptrCast(*anyopaque, @alignCast(@alignOf(*T), @constCast(&self.instance))), @ptrCast(*anyopaque, @alignCast(@alignOf(*P), @constCast(&params))));
      }
      return self;
    }

    /// Duplicate the instance
    pub fn dupe(self: *Self) !*Self {
      const dest = try self.allocator.create(Self);
      dest.allocator = self.allocator;
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
