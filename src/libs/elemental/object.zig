const std = @import("std");
const Mutex = std.Thread.Mutex;

pub const TypeObject = struct {
  parent: ?TypeObject,

  construct: fn(self: *type) void,
  destroy: fn(self: *type) void
};

pub fn Object(comptime info: TypeObject) type {
  return struct {
    parent: @TypeOf(Object(info.parent)),
    ref_lock: Mutex,
    ref_count: i32,

    const Self = @This();

    pub fn new() Self {
      const self = Self{
        .ref_count = 0
      };

      if (info.parent != null) {
        info.parent.construct(&self.parent);
      }

      info.construct(&self);
      return self;
    }

    pub fn ref(self: Self) Self {
      Mutex.lock(&self.ref_lock);
      self.ref_count += 1;
      Mutex.unlock(&self.ref_lock);
      return self;
    }

    pub fn unref(self: Self) void {
      Mutex.lock(&self.ref_lock);

      if (self.ref_count == 0) {
        info.destroy(&self);

        if (info.parent != null) {
          info.parent.destroy(&self.parent);
        }
      } else {
        self.ref_count -= 1;
      }

      Mutex.unlock(&self.ref_lock);
    }
  };
}
