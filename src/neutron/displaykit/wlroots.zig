const std = @import("std");
const base = @import("base.zig");
const graphics = @import("../graphics.zig");

pub const Compositor = @import("wlroots/compositor.zig");
pub const Output = @import("wlroots/output.zig");
pub const input = @import("wlroots/input.zig");

pub const Params = struct {
  base: base.Params,

  pub fn init() Params {
    return .{
      .base = .{
        .type = .compositor,
      },
    };
  }

  pub fn parseArgument(arg: []const u8) !Params {
    return .{
      .base = try base.Params.parseArgument(arg),
    };
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    if (self.path) |path| {
      try writer.writeAll("path=");
      try writer.writeAll(path);
      try writer.writeAll(",");
    }

    try self.base.format(fmt, options, writer);
  }
};

pub const Backend = union(base.Type) {
  client: void,
  compositor: *Compositor,

  pub fn init(params: Params, renderer: ?graphics.renderer.Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Backend {
    return switch (params.base.type) {
      .client => error.Unimplemented,
      .compositor => .{
        .compositor = try Compositor.new(.{
          .renderer = renderer,
        }, parent, allocator),
      },
    };
  }

  pub fn ref(self: *Backend, allocator: ?std.mem.Allocator) !Backend {
    return switch (self.*) {
      .client => error.Unimplemented,
      .compositor => |compositor| .{
        .compositor = try compositor.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Backend) void {
    return switch (self.*) {
      .client => @panic("Wlroots does not have a client backend, please use Wayland or X11"),
      .compositor => |compositor| compositor.unref(),
    };
  }

  pub fn toBase(self: *Backend) base.Backend {
    return switch (self.*) {
      .client => @panic("Wlroots does not have a client backend, please use Wayland or X11"),
      .compositor => |compositor| .{
        .compositor = &compositor.base_compositor,
      },
    };
  }
};
