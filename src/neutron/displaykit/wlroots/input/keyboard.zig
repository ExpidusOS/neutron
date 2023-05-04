const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const xkb = @import("xkbcommon");
const xkb_keymap = @import("../keymap.zig");
const Self = @This();
const Base = @import("base.zig");
const Keyboard = @import("../../base/input/keyboard.zig");
const Context = @import("../../base/context.zig");
const Compositor = @import("../compositor.zig");

const wl = @import("wayland").server.wl;
const wlr = @import("wlroots");

pub const Params = struct {
  context: *Context,
  device: *wlr.InputDevice,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    const kb = params.device.toKeyboard();

    const rules = xkb.RuleNames {
      .rules = std.c.getenv("XKB_DEFAULT_RULES"),
      .model = std.c.getenv("XKB_DEFAULT_MODEL"),
      .layout = std.c.getenv("XKB_DEFAULT_LAYOUT"),
      .variant = std.c.getenv("XKB_DEFAULT_VARIANT"),
      .options = std.c.getenv("XKB_DEFAULT_OPTIONS"),
    };

    const context = try (xkb.Context.new(.no_flags) orelse error.OutOfMemory);
    context.setLogLevel(if (builtin.mode == .Debug) .debug else .err);

    const keymap = try (xkb.Keymap.newFromNames(context, &rules, .no_flags) orelse error.OutOfMemory);
    std.debug.assert(kb.setKeymap(keymap));

    self.* = .{
      .type = t,
      .base_keyboard = try Keyboard.init(&self.base_keyboard, .{
        .context = params.context,
      }, self, self.type.allocator),
      .base = try Base.init(&self.base, .{
        .base = &self.base_keyboard.base,
        .device = params.device,
      }, self, self.type.allocator),
      .context = context,
      .keymap = keymap,
      .state = try (xkb.State.new(keymap) orelse error.OutOfMemory),
    };

    kb.events.key.add(&self.key);
    kb.events.modifiers.add(&self.modifiers);

    const compositor = self.getCompositor();

    var caps = @bitCast(wl.Seat.Capability, compositor.seat.capabilities);
    caps.keyboard = true;
    compositor.seat.setCapabilities(caps);
    compositor.seat.setKeyboard(kb);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .base_keyboard = undefined,
      .base = undefined,
      .context = self.context.ref(),
      .keymap = self.keymap.ref(),
      .state = self.state.ref(),
    };

    _ = try self.base_keyboard.type.refInit(&dest.base_keyboard, t.allocator);
    _ = try self.base.type.refInit(&dest.base, t.allocator);
  }

  pub fn unref(self: *Self) void {
    self.base.unref();
    self.base_keyboard.unref();

    self.state.unref();
    self.keymap.unref();
    self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

fn handleKey(self: *Self, keycode: u32, released: bool) !void {
  const compositor = self.getCompositor();
  const runtime = compositor.getRuntime();

  const keysym = self.state.keyGetOneSym(keycode);

  var message = std.ArrayList(u8).init(self.type.allocator);
  defer message.deinit();

  try std.json.stringify(.{
    .keymap = "linux",
    .toolkit = "gtk",
    .type = if (released) "keyup" 
      else "keydown",
    .keyCode = @enumToInt(keysym),
    .scanCode = keycode,
  }, .{}, message.writer());

  var resp_handle: ?*flutter.c.FlutterPlatformMessageResponseHandle = null;
  var result = runtime.proc_table.PlatformMessageCreateResponseHandle.?(runtime.engine, (struct {
    fn callback(data_ptr: [*c]const u8, data_size: usize, ud: ?*anyopaque) callconv(.C) void {
      _ = ud;

      if (data_ptr == null) return;

      var data = data_ptr[0..data_size];
      var ts = std.json.TokenStream.init(data);
      var msg = std.json.parse(struct {
        handled: bool
      }, &ts, .{}) catch unreachable;
      
      // TODO: pass unhandled events to seat
      _ = msg;
    }
  }).callback, self, &resp_handle);
  if (result != flutter.c.kSuccess) return error.EngineFail;
  errdefer _ = runtime.proc_table.PlatformMessageReleaseResponseHandle.?(runtime.engine, resp_handle);

  const pm = flutter.c.FlutterPlatformMessage {
    .struct_size = @sizeOf(flutter.c.FlutterPlatformMessage),
    .channel = "flutter/keyevent",
    .message = message.items.ptr,
    .message_size = message.items.len,
    .response_handle = resp_handle,
  };

  result = runtime.proc_table.SendPlatformMessage.?(runtime.engine, &pm);
  if (result != flutter.c.kSuccess) return error.EngineFail;
}

@"type": Type,
base_keyboard: Keyboard,
base: Base,
context: *xkb.Context,
keymap: *xkb.Keymap,
state: *xkb.State,
key: wl.Listener(*wlr.Keyboard.event.Key) = wl.Listener(*wlr.Keyboard.event.Key).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Keyboard.event.Key), event: *wlr.Keyboard.event.Key) void {
    const self = @fieldParentPtr(Self, "key", listener);

    self.handleKey(event.keycode + 8, event.state == .released) catch |err| {
      std.debug.print("Failed to handle keyboard event: {s}\n", .{ @errorName(err) });
      return;
    };
  }
}).callback),
modifiers: wl.Listener(*wlr.Keyboard) = wl.Listener(*wlr.Keyboard).init((struct {
  fn callback(listener: *wl.Listener(*wlr.Keyboard), _: *wlr.Keyboard) void {
    const self = @fieldParentPtr(Self, "modifiers", listener);
    const compositor = self.getCompositor();
    const kb = self.base.device.toKeyboard();

    compositor.seat.setKeyboard(kb);
    compositor.seat.keyboardNotifyModifiers(&kb.modifiers);
  }
}).callback),

pub usingnamespace Type.Impl;

pub inline fn getCompositor(self: *Self) *Compositor {
  return self.base.getCompositor();
}
