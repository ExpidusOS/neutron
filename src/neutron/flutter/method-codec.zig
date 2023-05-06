const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

pub const VTable = struct {
  decode: *const fn (self: *anyopaque, comptime T: type, message: []u8) anyerror!T,
  encode: *const fn (self: *anyopaque, data: anytype) anyerror![]u8,
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

pub fn decode(self: *Self, comptime T: type, message: []u8) !T {
  return self.vtable.decode(self.type.toOpaque(), T, message);
}

pub fn encode(self: *Self, data: anytype) ![]u8 {
  return self.vtable.encode(self.type.toOpaque(), data);
}
