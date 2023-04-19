const std = @import("std");
const elemental = @import("../../elemental.zig");
const FrameBuffer = @import("../fb.zig");
const Renderer = @import("../renderer/base.zig");
const Self = @This();

pub const VTable = struct {
  get_frame_buffer: *const fn (self: *anyopaque) anyerror!*FrameBuffer,
  commit_frame_buffer: *const fn (self: *anyopaque) anyerror!void,
  resize: *const fn (self: *anyopaque, res: @Vector(2, i32)) anyerror!void,
};

pub const Params = struct {
  vtable: *const VTable,
  renderer: *Renderer,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .vtable = params.vtable,
      .renderer = try params.renderer.ref(t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .vtable = self.vtable,
      .renderer = try self.renderer.ref(t.allocator),
    };
  }

  pub fn unref(self: *Self) void {
    self.renderer.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
vtable: *const VTable,
renderer: *Renderer,

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

pub fn getFrameBuffer(self: *Self) !*FrameBuffer {
  return self.vtable.get_frame_buffer(self.type.toOpaque());
}

pub fn commitFrameBuffer(self: *Self) !void {
  return self.vtable.commit_frame_buffer(self.type.toOpaque());
}

pub fn resize(self: *Self, res: @Vector(2, i32)) !void {
  return self.vtable.resize(self.type.toOpaque(), res);
}
