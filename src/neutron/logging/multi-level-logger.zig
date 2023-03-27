const std = @import("std");
const elemental = @import("../elemental.zig");
const Logger = @import("logger.zig");
const MultiLevelLogger = @This();

const vtable = Logger.VTable {
  .write = impl_write,
};

/// Instance creation parameters
pub const Params = struct {};

/// Neutron's Elemental type information
pub const TypeInfo = elemental.TypeInfo(MultiLevelLogger) {
  .init = impl_init,
  .construct = null,
  .destroy = impl_destroy,
  .dupe = impl_dupe,
};

/// Neutron's Elemental type definition
pub const Type = elemental.Type(MultiLevelLogger, Params, TypeInfo);

loggers: std.AutoHashMap(std.log.Level, *Logger),
logger: Logger.Type,

fn impl_write(_logger: *anyopaque, msg: Logger.Message) !void {
  const logger = @ptrCast(*Logger, @alignCast(@alignOf(Logger), _logger));
  const self = @fieldParentPtr(MultiLevelLogger, "logger", logger.getType());

  if (self.loggers.get(msg.level)) |use_logger| {
    try use_logger.write(msg);
  }
}

fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !MultiLevelLogger {
  const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
  _ = params;

  return .{
    .loggers = try std.AutoHashMap(std.log.Level, *Logger).init(allocator),
    .logger = try Logger.init(.{
      .vtable = &vtable
    }, allocator),
  };
}

fn impl_destroy(_self: *anyopaque) void {
  const self = @ptrCast(*MultiLevelLogger, @alignCast(@alignOf(MultiLevelLogger), _self));

  var iter = self.logger.iterator();
  while (iter.next()) |item| {
    item.value_ptr.*.unref();
  }

  self.loggers.deinit();
  self.logger.unref();
}

fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
  const self = @ptrCast(*MultiLevelLogger, @alignCast(@alignOf(MultiLevelLogger), _self));
  const dest = @ptrCast(*MultiLevelLogger, @alignCast(@alignOf(MultiLevelLogger), _dest));

  dest.loggers = try std.AutoHashMap(std.log.Level, *Logger).init(dest.getType().allocator);
  var iter = self.logger.iterator();
  while (iter.next()) |item| {
    try dest.logger.put(item.key_ptr.*, try item.value_ptr.*.dupe());
  }

  dest.logger = try self.logger.dupe();
}

pub fn new(params: Params, allocator: ?std.mem.Allocator) !*MultiLevelLogger {
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
