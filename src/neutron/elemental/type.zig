const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;

pub fn TypeInfo(comptime T: type, comptime P: type) type {
  return struct {
    construct: fn (self: *T, params: P) void,
    destroy: fn (self: *T) void,
    dupe: fn (self: *T, dest: *T) void,
  };
}

pub fn Type(comptime T: type, comptime P: type, comptime info: TypeInfo(T, P)) type {
  return struct {
    const Self = @This();

    pub const type_info = info;

    allocator: Allocator,
    comptime type_info: TypeInfo(T, P) = type_info,
    ref_count: i32,
    ref_lock: Mutex,
    instance: T,

    pub fn new(params: P, allocator: ?Allocator) !*Self {
      if (allocator == null) {
        return Self.new(params, std.heap.page_allocator);
      }

      const self = try allocator.?.create(Self);
      self.allocator = allocator.?;
      self.type_info = info;

      info.construct(&self.instance, params);
      return self;
    }

    pub fn dupe(self: *Self) !*Self {
      const dest = try self.allocator.create(Self);
      dest.allocator = self.allocator;
      dest.type_info = self.info;

      info.dupe(&self.instance, &dest.instance);
      return dest;
    }

    pub fn ref(self: *Self) *Self {
      Mutex.lock(&self.ref_lock);
      self.ref_count += 1;
      Mutex.unlock(&self.ref_lock);
      return self;
    }

    pub fn unref(self: *Self) void {
      Mutex.lock(&self.ref_lock);

      if (self.ref_count == 0) {
        defer {
          info.destroy(&self.instance);
          self.allocator.destroy(self);
        }
      } else {
        self.ref_count -= 1;
      }

      Mutex.unlock(&self.ref_lock);
    }
  };
}
