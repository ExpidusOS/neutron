const std = @import("std");
const elemental = @import("../../elemental.zig");
const Output = @import("../base/output.zig");
const BaseClient = @import("../base/client.zig");
const Context = @import("../base/context.zig");
const Client = @import("client.zig");
const Self = @This();

const wl = @import("wayland").client.wl;

pub const Params = struct {
  context: *Context,
  value: *wl.Output,
};

const vtable = Output.VTable {
  .get_resolution = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.resolution;
    }
  }).callback,
  .get_position = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.position;
    }
  }).callback,
  .get_scale = (struct {
    fn callback(_base: *anyopaque) f32 {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.scale;
    }
  }).callback,
  .get_physical_size = (struct {
    fn callback(_base: *anyopaque) @Vector(2, i32) {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.physical_size;
    }
  }).callback,
  .get_refresh_rate = (struct {
    fn callback(_base: *anyopaque) i32 {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return self.refresh;
    }
  }).callback,
  .get_id = (struct {
    fn callback(_base: *anyopaque) u32 {
      const base = Output.Type.fromOpaque(_base);
      const self = Type.fromOpaque(base.type.parent.?.getValue());
      return std.hash.CityHash32.hash(self.id);
    }
  }).callback,
};

fn listener(output: *wl.Output, event: wl.Output.Event, self: *Self) void {
  _ = output;

  switch (event) {
    .name => |name| {
      self.type.allocator.free(self.id);
      self.id = self.type.allocator.dupe(u8, name.name[0..std.mem.len(name.name)]) catch @panic("OOM");
    },
    .geometry => |geom| {
      self.position = .{ geom.x, geom.y };
      self.physical_size = .{ geom.physical_width, geom.physical_height };
    },
    .mode => |mode| {
      self.resolution = .{ mode.width, mode.height };
      self.refresh = mode.refresh;
    },
    .scale => |scale| {
      self.scale = std.math.lossyCast(f32, scale.factor);
    },
    else => {},
  }
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .base_output = undefined,
      .value = params.value,
      .id = try std.fmt.allocPrint(t.allocator, "UNKNOWN-{x}", .{ params.value }),
      .position = .{ 0, 0 },
      .physical_size = .{ 0, 0 },
      .resolution = .{ 0, 0 },
      .refresh = 0,
      .scale = 1.0,
    };

    _ = try Output.init(&self.base_output, .{
      .context = params.context,
      .vtable = &vtable,
    }, self, self.type.allocator);

    const client = self.getClient();
    self.value.setListener(*Self, listener, self);
    if (client.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFailed;
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_output = undefined,
      .value = self.value,
      .id = try t.allocator.dupe(u8, self.id),
      .position = self.position,
      .physical_size = self.physical_size,
      .resolution = self.resolution,
      .refresh = self.refresh,
      .scale = self.scale,
    };

    _ = try self.base_output.type.refInit(&dest.base_output, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base_output.unref();
    self.type.allocator.free(self.id);
  }

  pub fn destroy(self: *Self) void {
    self.value.release();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
base_output: Output,
value: *wl.Output,
id: []const u8,
position: @Vector(2, i32),
physical_size: @Vector(2, i32),
resolution: @Vector(2, i32),
refresh: i32,
scale: f32,

pub usingnamespace Type.Impl;

pub fn getClient(self: *Self) *Client {
  return @fieldParentPtr(Client, "base_client", @fieldParentPtr(BaseClient, "context", self.base_output.context));
}
