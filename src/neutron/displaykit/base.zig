const std = @import("std");

pub const Context = @import("base/context.zig");
pub const Compositor = @import("base/compositor.zig");
pub const Client = @import("base/client.zig");
pub const Output = @import("base/output.zig");
pub const input = @import("base/input.zig");
pub const View = @import("base/view.zig");
pub const Type = @import("base/base.zig").Type;

pub const Params = struct {
  @"type": Type,

  pub fn parseArgument(arg: []const u8) !Params {
    var params = Params {
      .type = .client,
    };

    var iter = std.mem.split(u8, arg, ",");
    while (iter.next()) |entry| {
      const sep_index = if (std.mem.indexOf(u8, entry, "=")) |value| value else continue;
      const key = entry[0..sep_index];
      const value = if (sep_index + 1 < entry.len) entry[(sep_index + 1)..] else continue;

      if (std.mem.eql(u8, key, "type")) {
        if (std.mem.eql(u8, value, "client")) params.type = .client
        else if (std.mem.eql(u8, value, "compositor")) params.type = .compositor
        else return error.InvalidType;
      } else {
        return error.InvalidKey;
      }
    }
    return params;
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.writeAll("type=");
    try writer.writeAll(switch (self.type) {
      .client => "client",
      .compositor => "compositor",
    });
  }
};

pub const Backend = union(Type) {
  client: *Client,
  compositor: *Compositor,

  pub fn init(_: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Backend {
    _ = parent;
    _ = allocator;
    @compileError("Not implemented!");
  }

  pub fn ref(self: *Backend, allocator: ?std.mem.Allocator) !Backend {
    return switch (self.*) {
      .client => |client| .{
        .client = try client.ref(allocator),
      },
      .compositor => |compositor| .{
        .compositor = try compositor.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Backend) !void {
    return switch (self.*) {
      .client => |client| client.unref(),
      .compositor => |compositor| compositor.unref(),
    };
  }

  pub fn toContext(self: *Backend) *Context {
    return switch (self.*) {
      .client => |client| &client.context,
      .compositor => |compositor| &compositor.context,
    };
  }
};
