const builtin = @import("builtin");
const std = @import("std");
const Mutex = std.Thread.Mutex;
const Reference = @This();

pub const Error = error {
  UnsetValue,
  Locked,
};

parent: ?*Reference = null,
children: ?std.ArrayList(*Reference) = null,
blocking: bool = true,
count: i32 = 0,
lock: Mutex = .{},
value: ?*anyopaque = null,

pub fn getTop(self: *Reference) *Reference {
  var item = self.parent;
  while (item) |value| : (item = value.parent) {
    if (value.parent == null) return value;
  }
  return self;
}

pub inline fn toOptionalValue(self: *Reference, comptime T: type) ?*T {
  return if (self.value) |value| @ptrCast(*T, @alignCast(@alignOf(T), value)) else null;
}

pub inline fn isValid(self: *Reference) bool {
  if (self.* == undefined) return false;
  if (self.value == null) return false;
  return true;
}

pub inline fn toRequiredValuePanic(self: *Reference, comptime T: type) *T {
  const value = self.toOptionalValue(T);
  return if (value == null) @panic("Type wanted to be set but got null") else value;
}

pub inline fn toRequiredValueError(self: *Reference, comptime T: type) Error!*T {
  const value = self.toOptionalValue(T);
  return if (value == null) error.UnsetValue else value;
}

pub inline fn toRequired(self: *Reference, comptime T: type) Error!*T {
  if (builtin.mode == .Debug) {
    return self.toRequiredValuePanic(T);
  }

  return self.toRequiredValueError(T);
}

pub fn runLock(self: *Reference) Error!void {
  const top = self.getTop();

  if (top.blocking) {
    Mutex.lock(&top.lock);
  } else {
    if (!Mutex.tryLock(&top.lock)) {
      return error.Locked;
    }
  }
}

pub fn ref(self: *Reference) Error!Reference {
  const top = self.getTop();
  try top.runLock();
  defer Mutex.unlock(&top.lock);

  top.count += 1;
  return Reference {
    .parent = self,
    .blocking = top.blocking,
    .count = top.count,
    .lock = .{},
    .value = self.value,
  };
}

pub fn unref(self: *Reference) void {
  const top = self.getTop();
  top.runLock() catch @panic("Cannot fail in unref due to lock error");

  if (top.count == 0 and self.children != null) {
    self.children.?.deinit();
  }

  if (top.count > 0) top.count -= 1;
  Mutex.unlock(&top.lock);

  self.value = null;
}
