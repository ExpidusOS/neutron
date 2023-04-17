const std = @import("std");
const config = @import("neutron-config");
const Mock = @import("displaykit/mock.zig");

pub const base = @import("displaykit/base.zig");
pub const wlroots = if (config.has_wlroots) @import("displaykit/wlroots.zig") else Mock("wlroots");

pub const Type = enum {
  wlroots,
};

pub const Params = union(Type) {
  wlroots: wlroots.Params,

  pub fn init(comptime t: Type) Params {
    return switch (t) {
      .wlroots => .{
        .wlroots = wlroots.Params.init(),
      },
    };
  }

  /// A zig-clap compatible parser for generating parameters
  pub fn parseArgument(arg: []const u8) !Params {
    inline for (comptime std.meta.fields(Params), comptime std.meta.fields(Type)) |u_field, e_field| {
      const arg_kind_sep = if (std.mem.indexOf(u8, arg, ":")) |value| value else arg.len;
      if (std.mem.eql(u8, arg[0..arg_kind_sep], u_field.name)) {
        var p = Params.init(@intToEnum(Type, e_field.value));
        const start_index = if (arg_kind_sep + 1 < arg.len) arg_kind_sep + 1 else arg.len;
        @field(p, u_field.name) = try u_field.type.parseArgument(arg[start_index..]);
        return p;
      }
    }
    return error.InvalidKind;
  }

  pub fn format(self: Params, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.writeAll(switch (self) {
      .wlroots => "wlroots",
    });

    try writer.writeByte(':');
    return switch (self) {
      .wlroots => |wlr| wlr.format(fmt, options, writer),
    };
  }
};

pub const Backend = union(Type) {
  wlroots: wlroots.Backend,

  pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Backend {
    return switch (params) {
      .wlroots => |params_wlroots| .{
        .wlroots = try wlroots.Backend.init(params_wlroots, parent, allocator),
      },
    };
  }

  pub fn ref(self: *Backend, allocator: ?std.mem.Allocator) !Backend {
    return switch (self.*) {
      .wlroots => .{
        .wlroots = try self.wlroots.ref(allocator),
      },
    };
  }

  pub fn unref(self: *Backend) !void {
    return switch (self.*) {
      .wlroots => self.wlroots.unref(),
    };
  }

  pub fn toBase(self: *Backend) base.Backend {
    return switch (self.*) {
      .wlroots => self.wlroots.toBase(),
    };
  }
};
