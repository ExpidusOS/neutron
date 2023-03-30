const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

pub const Params = struct {};

const Impl = struct {};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,

pub fn init(_: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return .{
    .type = Type.init(parent, allocator),
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
