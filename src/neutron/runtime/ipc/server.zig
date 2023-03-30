const std = @import("std");
const elemental = @import("../../elemental.zig");
const Runtime = @import("../runtime.zig");
const Base = @import("base.zig");
const Self = @This();

pub const Params = struct {
  runtime: *Runtime,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .base = try self.base.type.refInit(t.allocator),
    };
  }

  pub fn unref(self: *Self) !void {
    try self.base.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: Base,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  var self = Self {
    .type = Type.init(parent, allocator),
    .base = undefined,
  };

  self.base = try Base.init(.{
    .vtable = &.{},
    .runtime = params.runtime,
  }, &self, self.type.allocator);
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
