const std = @import("std");
const _type = @import("type.zig");
const mem = std.mem;
const Allocator = mem.Allocator;

pub fn TypedList(comptime T: type) type {
  return TypedListAligned(T, null);
}

pub fn TypedListAligned(comptime T: type, comptime alignment: ?u29) type {
  if (alignment) |a| {
    if (a == @alignOf(T)) {
      return TypedListAligned(T, null);
    }
  }

  return struct {
    const Self = @This();

    pub const Params = struct {};

    const Impl = struct {
      pub fn ref(self: *Self, dest: *Self, t: Type) !void {
        dest.* = .{
          .type = t,
          .items = &[_]T{},
          .capacity = 0,
        };

        try dest.ensureTotalCapacityPrecise(self.capacity);

        for (self.items) |item| {
          try dest.appendAssumeCapacity(item);
        }
      }

      pub fn unref(self: *Self) void {
        for (self.items) |item| item.unref();
        self.type.allocator.free(self.allocatedSlice());
      }
    };

    pub fn SentinelSlice(comptime s: T) type {
      return if (alignment) |a| ([:s]align(a) T) else [:s]T;
    }

    pub const Slice = if (alignment) |a| ([]align(a) T) else []T;
    pub const Type = _type.Type(Self, Params, Impl);

    @"type": Type,
    items: Slice = &[_]T{},
    capacity: usize = 0,

    pub usingnamespace Type.Impl;

    pub fn ensureTotalCapacity(self: *Self, new_cap: usize) Allocator.Error!void {
      if (self.capacity >= new_cap) return;

      var better_cap = self.capacity;
      while (true) {
        better_cap +|= better_cap / 2 + 8;
        if (better_cap >= new_cap) break;
      }

      return self.ensureTotalCapacityPrecise(better_cap);
    }

    pub fn ensureTotalCapacityPrecise(self: *Self, new_cap: usize) Allocator.Error!void {
      if (@sizeOf(T) == 0) {
        self.capacity = std.math.maxInt(usize);
        return;
      }

      if (self.capacity >= new_cap) return;

      const old_mem = self.allocatedSlice();
      if (self.type.allocator.resize(old_mem, new_cap)) {
        self.capacity = new_cap;
      } else {
        const new_mem = try self.type.allocator.alignedAlloc(T, alignment, new_cap);
        mem.copy(T, new_mem, self.items);
        self.type.allocator.free(old_mem);
        self.items.ptr = new_mem.ptr;
        self.capacity = new_mem.len;
      }
    }

    pub fn addOne(self: *Self) Allocator.Error!*T {
      const newlen = self.items.len + 1;
      try self.ensureTotalCapacity(newlen);
      return self.addOneAssumeCapacity();
    }

    pub fn addOneAssumeCapacity(self: *Self) *T {
      std.debug.assert(self.items.len < self.capacity);

      self.items.len += 1;
      return &self.items[self.items.len - 1];
    }

    pub fn appendAssumeCapacity(self: *Self, item: T) !void {
      const new_item_ptr = self.addOneAssumeCapacity();
      new_item_ptr.* = try item.ref(self.type.allocator);
    }

    pub fn append(self: *Self, item: T) !void {
      const new_item_ptr = try self.addOne();
      new_item_ptr.* = try item.ref(self.type.allocator);
    }

    pub fn appendOwned(self: *Self, item: T) !void {
      const new_item_ptr = try self.addOne();
      new_item_ptr.* = item;
    }

    pub fn allocatedSlice(self: *Self) Slice {
      return self.items.ptr[0..self.capacity];
    }

    pub fn remove(self: *Self, i: usize) ?T {
      if (self.items.len == 0) return null;
      if (self.items.len - 1 == i) return self.popOwned();

      const old_item = self.items[i];
      self.items[i] = self.popOwned().?;
      return old_item;
    }

    pub fn popOwned(self: *Self) ?T {
      if (self.items.len == 0) return null;

      const val = self.items[self.items.len - 1];
      self.items.len -= 1;
      return val;
    }

    pub fn pop(self: *Self) ?T {
      const val = self.popOwned();
      if (val) |v| {
        v.unref();
      }
      return val;
    }

    pub fn first(self: *Self) !?T {
      if (self.items.len == 0) return null;

      const val = self.items[0];
      return try val.ref(self.type.allocator);
    }

    pub fn last(self: *Self) !?T {
      if (self.items.len == 0) return null;

      const val = self.items[self.items.len - 1];
      return val.ref(self.type.allocator);
    }
  };
}
