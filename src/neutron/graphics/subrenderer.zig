const std = @import("std");

pub const Base = @import("subrenderer/base.zig");
pub const Egl = @import("subrenderer/egl.zig");

pub const Type = @import("renderer.zig").Type;

pub const Subrenderer = union(Type) {
  egl: *Egl,

  pub fn ref(self: *Subrenderer, allocator: ?std.mem.Allocator) !Subrenderer {
    return switch (self.*) {
      .egl => |egl| .{
        .egl = try egl.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Subrenderer) void {
    return switch (self.*) {
      .egl => |egl| egl.unref(),
    };
  }

  pub fn toBase(self: *Subrenderer) *Base {
    return switch (self.*) {
      .egl => |egl| &egl.base,
    };
  }
};
