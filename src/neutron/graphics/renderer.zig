const std = @import("std");
const hardware = @import("../hardware.zig");
const displaykit = @import("../displaykit.zig");

pub const Base = @import("renderer/base.zig");
pub const Egl = @import("renderer/egl.zig");

pub const Type = enum {
  egl,
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

    if (std.mem.indexOf(u8, arg, ":") != null) return error.InvalidKind;
    return parseSubarguments(null, arg);
  }
};

pub const Renderer = union(Type) {
  egl: *Egl,

  pub fn initGL(software: ?bool, _gpu: ?*hardware.device.Gpu, ctx: ?*displaykit.base.Context, allocator: ?std.mem.Allocator) !Renderer {
    if (software) |sw| {
      if (sw) {
        return error.NotSupported;
      } else {
        if (_gpu) |gpu| {
          return .{
            .egl = try Egl.new(gpu, ctx, allocator),
          };
        }
        return error.InvalidGpu;
      }
    }

    if (_gpu) |gpu| {
      if (Egl.new(gpu, ctx, allocator) catch |err| blk: {
        std.debug.print("Failed to create EGL renderer: {s}\n", .{ @errorName(err) });
        break :blk null;
      }) |egl| return .{ .egl = egl };
    }
    return error.NotSupported;
  }

  pub fn init(params: ?Params, _gpu: ?*hardware.device.Gpu, ctx: ?*displaykit.base.Context, allocator: ?std.mem.Allocator) !Renderer {
    if (params) |p| {
      if (p.kind) |kind| {
        return switch (kind) {
          .gl => Renderer.initGL(p.software, _gpu, ctx, allocator),
        };
      }

      if (Renderer.initGL(p.software, _gpu, ctx, allocator) catch null) |self| return self;
      return error.NotSupported;
    }

    return Renderer.init(Params.init(), _gpu, ctx, allocator);
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
