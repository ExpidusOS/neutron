const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

pub const LogMessage = struct {
  timestamp: i64,
  level: std.log.Level,
  message: []const u8,

  pub fn init(level: std.log.Level, message: []const u8) LogMessage {
    return .{
      .timestamp = std.time.timestamp(),
      .level = level,
      .message = message,
    };
  }
};

/// Virtual function table
pub const VTable = struct {
  write: *const fn (self: *anyopaque, msg: LogMessage) anyerror!void,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .vtable = self.vtable,
      .mutex = .{},
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
mutex: std.Thread.Mutex,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return .{
    .type = Type.init(parent, allocator),
    .vtable = params.vtable,
    .mutex = .{},
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

pub fn write(self: *Self, level: std.log.Level, message: []const u8) !void {
  self.mutex.lock();
  defer self.mutex.unlock();

  return self.vtable.write(self.type.toOpaque(), LogMessage.init(level, message));
}

pub inline fn err(self: *Self, message: []const u8) !void {
  return self.write(.err, message);
}

pub inline fn warn(self: *Self, message: []const u8) !void {
  return self.write(.warn, message);
}

pub inline fn info(self: *Self, message: []const u8) !void {
  return self.write(.info, message);
}

pub inline fn debug(self: *Self, message: []const u8) !void {
  return self.write(.debug, message);
}
