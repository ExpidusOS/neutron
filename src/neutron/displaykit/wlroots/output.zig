const std = @import("std");
const elemental = @import("../../elemental.zig");
const Output = @import("../base/output.zig");
const Context = @import("../base/context.zig");
const Compositor = @import("compositor.zig");
const Self = @This();
const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {
  context: *Context,
  value: *wlr.Output,
};

const vtable = Output.VTable {
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base_output = try Output.init(.{
        .context = params.context,
        .vtable = &vtable,
      }, self, self.type.allocator),
      .value = params.value,
    };

    errdefer self.base_output.unref();

    const compositor = self.getCompositor();
    std.debug.print("{}\n", .{ compositor });
    if (!self.value.initRender(compositor.allocator, compositor.renderer)) return error.RenderFailed;

    if (self.value.preferredMode()) |mode| {
      self.value.setMode(mode);
      self.value.enable(true);
      try self.value.commit();
    }

    compositor.output_layout.addAuto(self.value);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_output = try self.base_output.type.refInit(t.allocator),
      .value = self.value,
    };
  }

  pub fn unref(self: *Self) void {
    self.base_output.unref();
    self.value.destroy();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_output: Output,
value: *wlr.Output,

pub inline fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
  return Type.init(params, parent, allocator);
}

pub inline fn new(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*Self {
  return Type.new(params, parent, allocator);
}

pub inline fn ref(self: *Self, allocator: ?std.mem.Allocator) !*Self {
  return self.type.refNew(allocator);
}

pub inline fn unref(self: *Self) void {
  return self.type.unref();
}

pub inline fn getCompositor(self: *Self) *Compositor {
  return Compositor.Type.fromOpaque(self.base_output.context.toCompositor().type.parent.?);
}
