const std = @import("std");
const elemental = @import("../../../elemental.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  context: Context.VTable,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn ref(self: *Self, t: Type) !Self {
    return .{
      .type = t,
      .vtable = self.vtable,
      .context = try self.context.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) !void {
    try self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: Context,

pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  var self = Self {
    .type = Type.init(parent, allocator),
    .vtable = params.vtable,
    .context = undefined,
  };

  self.context = try Context.init(.{
    .vtable = &params.vtable.context,
  }, &self, allocator);
  return self;
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
