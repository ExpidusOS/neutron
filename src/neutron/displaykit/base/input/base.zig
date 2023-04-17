const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Context = @import("../context.zig");

pub const Params = struct {
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .context = try params.context.ref(t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .context = try self.context.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
context: *Context,

pub inline fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return Type.init(params, parent, allocator);
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}
