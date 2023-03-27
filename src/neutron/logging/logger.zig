const std = @import("std");
const elemental = @import("../elemental.zig");
const Logger = @This();

/// A single log message
pub const Message = struct {
  level: std.log.Level,
  timestamp: i64,
  value: []const u8,
};

/// Implementation specific functions
pub const VTable = struct {
  write: *const fn (self: *anyopaque, msg: Message) anyerror!void,
  format: ?*const fn (self: *anyopaque, level: std.log.Level, ts: i64, comptime fmt: []const u8, args: anytype) anyerror![]const u8 = null,
};

/// Instance creation parameters
pub const Params = struct {
  vtable: *const VTable,
  level: std.log.Level = .info,
};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(Logger) {
  .init = impl_init,
  .construct = null,
  .destroy = null,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(Logger, Params, TypeInfo);

level: std.log.Level,
vtable: *const VTable,

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Logger {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  _ = allocator;

  return .{
    .level = params.level,
    .vtable = params.vtable,
  };
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*Logger, @alignCast(@alignOf(Logger), _self));
  const dest = @ptrCast(*Logger, @alignCast(@alignOf(Logger), _dest));

  dest.level = self.level;
  dest.vtable = self.vtable;
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Logger {
  return &(try Type.new(params, allocator)).instance;
}

pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
  return try Type.init(params, allocator);
}

/// Gets the Elemental type definition instance for this instance
pub fn getType(self: *Logger) *Type {
  return @fieldParentPtr(Type, "instance", self);
}

/// Increases the reference count and return the instance
pub fn ref(self: *Logger) *Logger {
  return &(self.getType().ref().instance);
}

/// Decreases the reference count and free it if the counter is 0
pub fn unref(self: *Logger) void {
  return self.getType().unref();
}

pub fn dupe(self: *Logger) !*Logger {
  return &(try self.getType().dupe()).instance;
}

pub fn write(self: *Logger, level: std.log.Level, value: []const u8) !void {
  return self.vtable.write(self, .{
    .level = level,
    .value = value,
    .timestamp = std.time.timestamp(),
  });
}

pub fn writeFormat(self: *Logger, level: std.log.Level, comptime fmt: []const u8, args: anytype) !void {
  const str = try (if (self.vtable.format) |format| format(self, level, std.time.timestamp(), fmt, args)
    else std.fmt.allocPrint(self.getType().allocator, fmt, args));
  defer self.getType().allocator.free(str);
  return self.write(level, str);
}

pub inline fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
  return self.writeFormat(.debug, fmt, args);
}

pub inline fn info(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
  return self.writeFormat(.info, fmt, args);
}

pub inline fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
  return self.writeFormat(.warn, fmt, args);
}

pub inline fn err(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
  return self.writeFormat(.err, fmt, args);
}
