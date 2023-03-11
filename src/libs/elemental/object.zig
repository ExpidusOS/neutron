const std = @import("std");
const builtin = std.builtin;
const Mutex = std.Thread.Mutex;

pub const ObjectType = struct {
  name: []const u8,
  value: type,
  parent: ?*const ObjectType,
  construct: fn (value: *?*anyopaque) void,
  destroy: fn (value: *?*anyopaque) void,
};

pub fn Object(comptime type_info: ObjectType) type {
  const Parent = if (type_info.parent != null)
    Object(type_info.parent.?.*)
  else
    struct {
      const Self = @This();

      allocator: std.mem.Allocator,
      ref_count: i32,
      ref_lock: Mutex,

      pub fn ref(self: *Self) *Self {
        return self;
      }

      pub fn unref(self: *Self) void {
        _ = self;
      }
    };

  return struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    ref_count: i32,
    ref_lock: Mutex,
    value: ?* type_info.value,
    parent: ?*Parent,

    pub fn new(allocator: ?std.mem.Allocator) !*Self {
      if (allocator == null) {
        return try Self.new(std.heap.page_allocator);
      }

      const self = try allocator.?.create(Self);

      if (type_info.parent != null) {
        self.parent = Parent.new(allocator);
      } else {
        self.parent = null;
      }

      if (@sizeOf(type_info.value) > 0) {
        self.value = try allocator.?.create(type_info.value);
      } else {
        self.value = null;
      }

      self.allocator = allocator.?;
      self.ref_count = 0;

      type_info.construct(@ptrCast(*?*anyopaque, &self.value));
      return self;
    }

    pub fn ref(self: *Self) *Self {
      Mutex.lock(&self.ref_lock);
      self.ref_count += 1;
      Mutex.unlock(&self.ref_lock);
      return self;
    }

    pub fn getObjectInstance(self: *Self, type_name: []const u8) ?type {
      if (type_info.name == type_name) return self;
      if (type_info.parent == null) return null;
      return self.parent.getObjectInstance(type_name);
    }

    pub fn unref(self: *Self) void {
      Mutex.lock(&self.ref_lock);

      if (self.ref_count == 0) {
        if (self.parent != null) {
          self.parent.?.unref();
        }

        type_info.destroy(@ptrCast(*?*anyopaque, &self.value));
      } else {
        self.ref_count -= 1;
      }

      Mutex.unlock(&self.ref_lock);

      if (self.ref_count == 0) {
        if (self.value != null) {
          self.allocator.destroy(self.value.?);
        }

        self.allocator.destroy(self);
      }
    }
  };
}
