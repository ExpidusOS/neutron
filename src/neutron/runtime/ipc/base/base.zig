const std = @import("std");
const xev = @import("xev");
const elemental = @import("../../../elemental.zig");
const Runtime = @import("../../runtime.zig");
const Self = @This();

pub const VTable = struct {
};

pub const Params = struct {
  vtable: *const VTable,
  runtime: *Runtime,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    var dest = Self {
      .type = t,
      .vtable = self.vtable,
      .runtime = self.runtime,
      .loop = try xev.Loop.init(.{}),
      .thread = null,
    };

    if (self.running) try dest.start();
    return dest;
  }

  pub fn unref(self: *Self) !void {
    if (self.running) try self.stop();
    self.loop.deinit();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
runtime: *Runtime,
loop: xev.Loop,
running: bool = false,
thread: ?std.Thread,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  var self = Self {
    .type = Type.init(parent, allocator),
    .vtable = params.vtable,
    .runtime = params.runtime,
    .loop = try xev.Loop.init(.{}),
    .thread = null,
  };
  errdefer self.loop.deinit();
  return self;
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) !void {
  return self.type.unref();
}

pub fn start(self: *Self) !void {
  if (self.running) return error.AlreadyStarted;

  self.thread = try std.Thread.spawn(.{}, (struct {
    pub fn callback(base: *Self) !void {
      base.running = true;
      errdefer base.running = false;
      try base.loop.run(.until_done);
    }
  }).callback, .{ self });
}

pub fn stop(self: *Self) !void {
  if (!self.running) return error.NotStarted;

  self.loop.stop();
  self.thread.?.join();
  self.running = false;
  self.thread = null;
}