const std = @import("std");
const hardware = @import("../hardware.zig");
const displaykit = @import("../displaykit.zig");

pub const Base = @import("renderer/base.zig");
pub const Egl = @import("renderer/egl.zig");

pub const Type = enum {
  egl,
};

pub const Params = struct {
  gpu: ?*hardware.device.Gpu,
  displaykit: ?*displaykit.base.Context,
  resolution: @Vector(2, i32),
};

pub const Renderer = union(Type) {
  egl: *Egl,

  pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Renderer {
    if (params.gpu) |gpu| {
      if (Egl.new(.{
        .gpu = gpu,
        .displaykit = params.displaykit,
        .resolution = params.resolution,
      }, parent, allocator) catch |err| blk: {
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

  pub fn unref(self: *Renderer) void {
    return switch (self.*) {
      .egl => |egl| egl.unref(),
    };
  }
};
