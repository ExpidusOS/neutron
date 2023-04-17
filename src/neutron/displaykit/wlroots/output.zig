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

fn effectiveResTry(self: *Self) bool {
  var width: c_int = undefined;
  var height: c_int = undefined;
  self.value.effectiveResolution(&width, &height);

  const rates = [_]i32 { 64, 32, 24, 16, 8, 4, 2 };
  for (rates) |rate| {
    self.value.setCustomMode(width, height, rate);
    self.value.enable(true);
    self.value.commit() catch continue;
    return true;
  }
  return false;
}

fn iterateResTry(self: *Self) bool {
  var it = self.value.modes.iterator(.forward);
  while (it.next()) |mode| {
    self.value.setMode(mode);
    self.value.enable(true);
    self.value.commit() catch continue;
    return true;
  }
  return false;
}

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
    if (!self.value.initRender(compositor.allocator, compositor.renderer)) return error.RenderFailed;

    if (self.value.preferredMode()) |preferred_mode| {
      self.value.setMode(preferred_mode);
      self.value.enable(true);
      self.value.commit() catch {
        if (!iterateResTry(self)) {
          _ = effectiveResTry(self);
        }
      };
    } else {
      if (!iterateResTry(self)) {
        _ = effectiveResTry(self);
      }
    }

    self.value.events.frame.add(&self.frame);
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
frame: wl.Listener(*wlr.Output) = wl.Listener(*wlr.Output).init((struct {
  pub fn callback(listener: *wl.Listener(*wlr.Output), _: *wlr.Output) void {
    const self = @fieldParentPtr(Self, "frame", listener);

    const scene_output = self.getCompositor().scene.getSceneOutput(self.value).?;
    _ = scene_output.commit();

    var now: std.os.timespec = undefined;
    std.os.clock_gettime(std.os.CLOCK.MONOTONIC, &now) catch @panic("CLOCK_MONOTONIC not supported");
    scene_output.sendFrameDone(&now);
  }
}).callback),

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
  return Compositor.Type.fromOpaque(self.type.parent.?);
}
