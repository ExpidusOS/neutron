const builtin = @import("builtin");
const std = @import("std");
const Mutex = std.Thread.Mutex;
const Reference = @This();

pub const Error = error {
  UnsetValue,
  Locked,
};

pub const Flags = packed struct {
  created: bool,
  blocking: bool,
};

flags: Flags = @bitCast(Flags, Flags {
  .created = true,
  .blocking = true,
}),
parent: ?*Reference = null,
children: ?std.ArrayList(*Reference) = null,
count: i32 = 0,
lock: Mutex = .{},
value: ?*anyopaque = null,

pub fn getTop(self: *Reference) *Reference {
  std.debug.assert(self.isValid());

  var item = self.parent;
  while (item) |value| : (item = value.parent) {
    if (value.parent == null) return value;
  }
  return self;
}

pub inline fn toOptionalValue(self: *Reference, comptime T: type) ?*T {
  std.debug.assert(self.isValid());
  return if (self.value) |value| @ptrCast(*T, @alignCast(@alignOf(T), value)) else null;
}

pub inline fn isValid(self: *Reference) bool {
  return @bitCast(Flags, self.flags).created;
}

pub inline fn toRequiredValuePanic(self: *Reference, comptime T: type) *T {
  std.debug.assert(self.isValid());
  const value = self.toOptionalValue(T);
  return if (value == null) @panic("Type wanted to be set but got null") else value;
}

pub inline fn toRequiredValueError(self: *Reference, comptime T: type) Error!*T {
  std.debug.assert(self.isValid());
  const value = self.toOptionalValue(T);
  return if (value == null) error.UnsetValue else value;
}

pub inline fn toRequired(self: *Reference, comptime T: type) Error!*T {
  std.debug.assert(self.isValid());

  if (builtin.mode == .Debug) {
    return self.toRequiredValuePanic(T);
  }

  return self.toRequiredValueError(T);
}

pub fn runLock(self: *Reference) Error!void {
  std.debug.assert(self.isValid());

  const top = self.getTop();

  if (top.flags.blocking) {
    Mutex.lock(&top.lock);
  } else {
    if (!Mutex.tryLock(&top.lock)) {
      return error.Locked;
    }
  }
}

pub fn ref(self: *Reference) Error!Reference {
  std.debug.assert(self.isValid());

  const top = self.getTop();
  try top.runLock();
  defer Mutex.unlock(&top.lock);

  top.count += 1;
  return Reference {
    .flags = self.flags,
    .parent = self,
    .count = top.count,
    .lock = .{},
    .value = self.value,
  };
}

pub fn unref(self: *Reference) void {
  std.debug.assert(self.isValid());

  const top = self.getTop();
  top.runLock() catch @panic("Cannot fail in unref due to lock error");

  if (top.count == 0 and self.children != null) {
    for (self.children.?.items) |child| {
      child.parent = null;
    }

    self.children.?.deinit();
  }

  if (top.count > 0) top.count -= 1;
  self.count -= 1;

  Mutex.unlock(&top.lock);

  var flags = @bitCast(Flags, self.flags);
  flags.created = false;

  self.value = null;
  self.flags = @bitCast(Flags, flags);
}
