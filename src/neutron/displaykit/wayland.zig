const std = @import("std");
const base = @import("base.zig");
const graphics = @import("../graphics.zig");

pub const Client = @import("wayland/client.zig");

pub const Params = struct {
  base: base.Params,
  display: ?[]const u8,
  width: i32,
  height: i32,

  pub fn init() Params {
    return .{
      .base = .{
        .type = .client,
      },
      .display = null,
      .width = 1024,
      .height = 768,
    };
  }

  pub fn parseArgument(arg: []const u8) !Params {
    var params = Params {
      .base = .{
        .type = .client,
      },
      .display = null,
      .width = 1024,
      .height = 768,
    };

    var iter = std.mem.split(u8, arg, ",");
    var index: usize = 0;
    while (iter.next()) |entry| {
      const sep_index = if (std.mem.indexOf(u8, entry, "=")) |value| value else continue;
      const key = entry[0..sep_index];
      const value = if (sep_index + 1 < entry.len) entry[(sep_index + 1)..] else continue;

      if (std.mem.eql(u8, key, "display")) {
        if (params.display != null) return error.DuplicateKey;

        params.display = value;
      } else {
        params.base = try base.Params.parseArgument(arg[index..]);
      }

      index += entry.len + 1;
    }

    return params;
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    try self.base.format(fmt, options, writer);
  }
};

pub const Backend = union(base.Type) {
  client: *Client,
  compositor: void,

  pub fn init(params: Params, renderer: ?graphics.renderer.Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Backend {
    return switch (params.base.type) {
      .client => .{
        .client = try Client.new(.{
          .renderer = renderer,
          .display = params.display,
          .width = params.width,
          .height = params.height,
        }, parent, allocator),
      },
      .compositor => error.Unimplemented,
    };
  }

  pub fn ref(self: Backend, allocator: ?std.mem.Allocator) !Backend {
    return switch (self) {
      .client => |client| .{
        .client = try client.ref(allocator),
      },
      .compositor => error.Unimplemented,
    };
  }

  pub fn unref(self: Backend) void {
    return switch (self) {
      .client => |client| client.unref(),
      .compositor => @panic("Wayland does not have a compositor backend, please use Wlroots or X11"),
    };
  }

  pub fn toBase(self: Backend) base.Backend {
    return switch (self) {
      .client => |client| .{
        .client = &client.base_client,
      },
      .compositor => @panic("Wayland does not have a compositor backend, please use Wlroots or X11"),
    };
  }
};
