const std = @import("std");
const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const Self = @This();
const Context = @import("context.zig");

/// Virtual function table
pub const VTable = struct {
  get_resolution: *const fn (self: *anyopaque) @Vector(2, i32),
};

pub const Params = struct {
  vtable: *const VTable,
  context: *Context,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .context = try params.context.ref(t.allocator),
      .renderer = try graphics.renderer.Renderer.init(.{
        .gpu = params.context.gpu,
        .displaykit = self.context,
        .resolution = self.getResolution(),
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .context = try self.context.ref(t.allocator),
      .renderer = try self.renderer.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.renderer.unref();
    self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
context: *Context,
renderer: graphics.renderer.Renderer,

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

pub fn getResolution(self: *Self) @Vector(2, i32) {
  return self.vtable.get_resolution(self.type.toOpaque());
}
