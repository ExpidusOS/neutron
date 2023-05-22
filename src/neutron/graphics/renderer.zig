const std = @import("std");
const config = @import("neutron-config");

pub const Base = @import("renderer/base.zig");
pub const Mock = @import("renderer/mock.zig");
pub const Egl = @import("renderer/egl.zig");
pub const OsMesa = if (config.has_osmesa) @import("renderer/osmesa.zig") else Mock;

pub const Type = enum {
  egl,
  osmesa,
};

pub const Kind = enum {
  gl,
};

pub const Params = struct {
  kind: ?Kind,
  software: ?bool,

  pub fn init() Params {
    return .{
      .kind = null,
      .software = null,
    };
  }

  fn parseSubarguments(kind: ?Kind, arg: []const u8) !Params {
    var params = Params {
      .kind = kind,
      .software = null,
    };

    var iter = std.mem.split(u8, arg, ",");
    while (iter.next()) |entry| {
      const sep_index = if (std.mem.indexOf(u8, entry, "=")) |value| value else continue;
      const key = entry[0..sep_index];
      const value = if (sep_index + 1 < entry.len) entry[(sep_index + 1)..] else continue;

      if (std.mem.eql(u8, key, "software")) {
        if (std.mem.eql(u8, value, "true")) params.software = true
        else if (std.mem.eql(u8, value, "false")) params.software = false
        else if (std.mem.eql(u8, value, "dont-care")) params.software = null;
      } else if (std.mem.eql(u8, key, "hardware")) {
        if (std.mem.eql(u8, value, "true")) params.software = false
        else if (std.mem.eql(u8, value, "false")) params.software = true
        else if (std.mem.eql(u8, value, "dont-care")) params.software = null;
      } else {
        return error.InvalidKey;
      }
    }
    return params;
  }

  /// A zig-clap compatible parser for generating parameters
  pub fn parseArgument(arg: []const u8) !Params {
    inline for (@typeInfo(Kind).Enum.fields) |field| {
      const arg_kind_sep = if (std.mem.indexOf(u8, arg, ":")) |value| value else arg.len;
      if (std.mem.eql(u8, arg[0..arg_kind_sep], field.name)) {
        const start_index = if (arg_kind_sep + 1 < arg.len) arg_kind_sep + 1 else arg.len;
        return parseSubarguments(@intToEnum(Kind, field.value), arg[start_index..]);
      }
    }

    if (std.mem.indexOf(u8, arg, ",") == null) return error.InvalidKind;
    return parseSubarguments(null, arg);
  }
};

pub const Renderer = union(Type) {
  egl: *Egl,
  osmesa: *OsMesa,

  pub fn initGL(software: ?bool, params: Base.CommonParams, allocator: ?std.mem.Allocator) !Renderer {
    if (software) |sw| {
      if (sw) {
        return .{
          .osmesa = try OsMesa.new(params, null, allocator),
        };
      } else {
        if (params.gpu) |_| {
          return .{
            .egl = try Egl.new(params, null, allocator),
          };
        }
        return error.InvalidGpu;
      }
    }

    if (params.gpu) |_| {
      if (Egl.new(params, null, allocator) catch |err| blk: {
        std.debug.print("Failed to create EGL renderer: {s}\n", .{ @errorName(err) });
        std.debug.dumpStackTrace(@errorReturnTrace().?.*);
        break :blk null;
      }) |egl| return .{ .egl = egl };
    }

    return .{
      .osmesa = try OsMesa.new(params, null, allocator),
    };
  }

  pub fn init(params: ?Params, options: Base.CommonParams, allocator: ?std.mem.Allocator) !Renderer {
    if (params) |p| {
      if (p.kind) |kind| {
        return switch (kind) {
          .gl => Renderer.initGL(p.software, options, allocator),
        };
      }

      if (Renderer.initGL(p.software, options, allocator) catch null) |self| return self;
      return error.NotSupported;
    }

    return Renderer.init(Params.init(), options, allocator);
  }

  pub fn ref(self: Renderer, allocator: ?std.mem.Allocator) !Renderer {
    return switch (self) {
      .egl => |egl| .{
        .egl = try egl.ref(allocator),
      },
      .osmesa => |osmesa| .{
        .osmesa = try osmesa.ref(allocator),
      },
    };
  }

  pub fn unref(self: Renderer) void {
    return switch (self) {
      .egl => |egl| egl.unref(),
      .osmesa => |osmesa| osmesa.unref(),
    };
  }

  pub fn toBase(self: Renderer) *Base {
    return switch (self) {
      .egl => |egl| &egl.base,
      .osmesa => |osmesa| &osmesa.base,
    };
  }
};
