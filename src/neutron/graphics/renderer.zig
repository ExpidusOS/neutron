const std = @import("std");
const hardware = @import("../hardware.zig");
const displaykit = @import("../displaykit.zig");

pub const Base = @import("renderer/base.zig");
pub const Egl = @import("renderer/egl.zig");

pub const Type = enum {
  egl,
};

pub const Renderer = union(Type) {
  egl: *Egl,

  pub fn init(_gpu: ?*hardware.device.Gpu, ctx: ?*displaykit.base.Context, allocator: ?std.mem.Allocator) !Renderer {
    if (_gpu) |gpu| {
      if (Egl.new(gpu, ctx, allocator) catch |err| blk: {
        std.debug.print("Failed to create EGL renderer: {s}\n", .{ @errorName(err) });
        break :blk null;
      }) |egl| return .{ .egl = egl };
    }
    
    // TODO: try osmesa and buffered renderers
    return error.InvalidGpu;
  }

  pub fn ref(self: *Renderer, allocator: ?std.mem.Allocator) !Renderer {
    return switch (self.*) {
      .egl => |egl| .{
        .egl = try egl.ref(allocator),
      },
    };
  }

  pub fn setDisplayKit(self: *Renderer, ctx: ?*displaykit.base.Context) void {
    switch (self.*) {
      .egl => |egl| {
        egl.type.parent = Egl.Type.Parent.init(ctx);
      },
    }
  }

  pub fn getDisplayKit(self: *Renderer) ?*displaykit.base.Context {
    return switch (self.*) {
      .egl => |egl| egl.getDisplayKit(),
    };
  }

  pub fn unref(self: *Renderer) void {
    return switch (self.*) {
      .egl => |egl| egl.unref(),
    };
  }

  pub fn toBase(self: *Renderer) *Base {
    return switch (self.*) {
      .egl => |egl| &egl.base,
    };
  }
};
