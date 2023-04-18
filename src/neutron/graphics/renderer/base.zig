const std = @import("std");
const elemental = @import("../../elemental.zig");
const subrenderer = @import("../subrenderer.zig");
const Self = @This();

pub const VTable = struct {
  create_subrenderer: *const fn (self: *anyopaque, res: @Vector(2, i32)) anyerror!subrenderer.Subrenderer,
};

pub const Params = struct {
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,

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

pub fn createSubrenderer(self: *Self, res: @Vector(2, i32)) !subrenderer.Subrenderer {
  return self.vtable.create_subrenderer(self.type.toOpaque(), res);
}
