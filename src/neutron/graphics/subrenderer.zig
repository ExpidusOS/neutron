const std = @import("std");
const config = @import("neutron-config");

pub const Base = @import("subrenderer/base.zig");
pub const Mock = @import("subrenderer/mock.zig");
pub const Egl = @import("subrenderer/egl.zig");
pub const OsMesa = if (config.has_osmesa) @import("subrenderer/osmesa.zig") else Mock;

pub const Type = @import("renderer.zig").Type;

pub const Subrenderer = union(Type) {
  egl: *Egl,
  osmesa: *OsMesa,

  pub fn ref(self: *Subrenderer, allocator: ?std.mem.Allocator) !Subrenderer {
    return switch (self.*) {
      .egl => |egl| .{
        .egl = try egl.ref(allocator),
      },
      .osmesa => |osmesa| .{
        .osmesa = try osmesa.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Subrenderer) void {
    return switch (self.*) {
      .egl => |egl| egl.unref(),
      .osmesa => |osmesa| osmesa.unref(),
    };
  }

  pub fn toBase(self: *Subrenderer) *Base {
    return switch (self.*) {
      .egl => |egl| &egl.base,
      .osmesa => |osmesa| &osmesa.base,
    };
  }
};
