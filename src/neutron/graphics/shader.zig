const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

pub const Kind = enum {
  vertex,
  fragment,
};

pub const VTable = struct {
  set_code: *const fn (self: *anyopaque, code: []const u8) anyerror!void,
};

pub const Params = struct {
  vtable: *const VTable,
  kind: Kind,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .kind = self.kind,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .kind = self.kind,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
kind: Kind,
vtable: *const VTable,

pub usingnamespace Type.Impl;

pub fn setCode(self: *Self, code: []const u8) !void {
  return self.vtable.set_code(self.type.toOpaque(), code);
}
