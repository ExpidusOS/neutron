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
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .mutex = .{},
      .debug_info = try std.debug.openSelfDebugInfo(t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
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

pub fn write(self: *Self, level: std.log.Level, message: []const u8, addr: usize) !void {
  self.mutex.lock();
  defer self.mutex.unlock();

  const module = try self.debug_info.getModuleForAddress(addr);
  const sym = try module.getSymbolAtAddress(self.type.allocator, addr);

  const file = if (sym.line_info) |line| try std.fmt.allocPrint(self.type.allocator, "{s}:{}.{}", .{ line.file_name, line.line, line.column })
    else try std.fmt.allocPrint(self.type.allocator, "{s} ({s})", .{ sym.symbol_name, sym.compile_unit_name });
  return self.vtable.write(self.type.toOpaque(), LogMessage.init(level, file, message));
}

pub fn err(self: *Self, message: []const u8) !void {
  return self.write(.err, message, @returnAddress());
}

pub fn warn(self: *Self, message: []const u8) !void {
  return self.write(.warn, message, @returnAddress());
}

pub fn info(self: *Self, message: []const u8) !void {
  return self.write(.info, message, @returnAddress());
}

pub fn debug(self: *Self, message: []const u8) !void {
  return self.write(.debug, message, @returnAddress());
}

pub fn print(self: *Self, level: std.log.Level, comptime fmt: []const u8, args: anytype, addr: usize) !void {
  const message = try std.fmt.allocPrint(self.type.allocator, fmt, args);
  defer self.type.allocator.free(message);
  try self.write(level, message, addr);
}

pub fn fmtErr(self: *Self, comptime fmt: []const u8, args: anytype) !void {
  return self.print(.err, fmt, args, @returnAddress());
}

pub fn fmtWarn(self: *Self, comptime fmt: []const u8, args: anytype) !void {
  return self.print(.warn, fmt, args, @returnAddress());
}

pub fn fmtInfo(self: *Self, comptime fmt: []const u8, args: anytype) !void {
  return self.print(.info, fmt, args, @returnAddress());
}

pub fn fmtDebug(self: *Self, comptime fmt: []const u8, args: anytype) !void {
  return self.print(.debug, fmt, args, @returnAddress());
}
