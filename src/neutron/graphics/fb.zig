const std = @import("std");
const elemental = @import("../elemental.zig");
const Self = @This();

pub const Data = struct {
  resolution: @Vector(2, i32),
  stride: u32,
  format: u32,
  bpp: u32,
  buffer: *anyopaque,
};

pub const VTable = struct {
  get_resolution: *const fn (self: *anyopaque) @Vector(2, i32),
  get_stride: *const fn (self: *anyopaque) u32,
  get_format: *const fn (self: *anyopaque) u32,
  get_bpp: *const fn (self: *anyopaque) u32,
  get_buffer: *const fn (self: *anyopaque) *anyopaque,
};

pub const Params = union(enum) {
  data: Data,
  vtable: *const VTable,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .value = params,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .value = self.value,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
value: Params,

pub usingnamespace Type.Impl;

fn getData(self: *Self, comptime T: type, comptime field: []const u8) T {
  return switch (self.value) {
    .data => |data| @field(data, field),
    .vtable => |vtable| @field(vtable, "get_" ++ field)(self.type.toOpaque()),
  };
}

pub fn getResolution(self: *Self) @Vector(2, i32) {
  return self.getData(@Vector(2, i32), "resolution");
}

pub fn getStride(self: *Self) u32 {
  return self.getData(u32, "stride");
}

pub fn getFormat(self: *Self) u32 {
  return self.getData(u32, "format");
}

pub fn getBpp(self: *Self) u32 {
  return self.getData(u32, "bpp");
}

pub fn getBuffer(self: *Self) *anyopaque {
  return self.getData(*anyopaque, "buffer");
}
