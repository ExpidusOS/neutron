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
  pub fn init(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .mutex = .{},
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !Self {
    dest.* = .{
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

pub usingnamespace Type.Impl;

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
