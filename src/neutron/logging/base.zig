const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

pub const LogMessage = struct {
  timestamp: i64,
  level: std.log.Level,
  message: []const u8,
  file: []const u8,

  pub fn init(level: std.log.Level, file: []const u8, message: []const u8) LogMessage {
    return .{
      .timestamp = std.time.timestamp(),
      .level = level,
      .message = message,
      .file = file,
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
      .debug_info = try std.debug.openSelfDebugInfo(t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !Self {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .mutex = .{},
      .debug_info = try std.debug.openSelfDebugInfo(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.debug_info.deinit();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
mutex: std.Thread.Mutex,
debug_info: std.debug.DebugInfo,

pub usingnamespace Type.Impl;

pub fn write(self: *Self, level: std.log.Level,  message: []const u8) !void {
  self.mutex.lock();
  defer self.mutex.unlock();

  const module = try self.debug_info.getModuleForAddress(@returnAddress());
  defer module.deinit();

  const sym = try module.getSymbolAtAddress(self.type.allocator, @returnAddress());
  defer sym.deinit();

  const file = if (sym.line_info) |line| try std.fmt.allocPrint(self.type.allocator, "{}:{}.{}", .{ line.file_name, line.line, line.column })
    else try std.fmt.allocPrint(self.type.allocator, "{} ({})", .{ sym.symbol_name, sym.compile_unit_name });
  return self.vtable.write(self.type.toOpaque(), LogMessage.init(level, file, message));
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
