const elemental = @import("../../elemental.zig");
const graphics = @import("../../graphics.zig");
const hardware = @import("../../hardware.zig");
const Context = @import("../base/context.zig");
const eglApi = @import("../../graphics/api/egl.zig");
const Self = @This();

const wl = @import("wayland").client.wl;

const vtable = graphics.FrameBuffer.VTable {};

pub const Params = struct {
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    _ = params;

    self.* = .{
      .type = t,
      .base = try graphics.FrameBuffer.init(&self.base, .{
        .vtable = &vtable,
      }, self, t.allocator),
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base = undefined,
    };

    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
  }

  pub fn destroy(self: *Self) void {
    _ = self;
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base: graphics.FrameBuffer,
