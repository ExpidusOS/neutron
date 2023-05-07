const builtin = @import("builtin");
const std = @import("std");
const elemental = @import("../../../elemental.zig");
const flutter = @import("../../../flutter.zig");
const xkb = @import("xkbcommon");
const Self = @This();
const Keyboard = @import("../../base/input/keyboard.zig");
const Context = @import("../../base/context.zig");
const BaseClient = @import("../../base/client.zig");
const Client = @import("../client.zig");

const wl = @import("wayland").client.wl;

pub const Params = struct {
  context: *Context,
  value: *wl.Keyboard,
};

fn updateKeymap(self: *Self, fd: i32, size: u32) !void {
  if (self.keymap) |km| {
    km.unref();
    self.keymap = null;
  }

  if (self.state) |state| {
    state.unref();
    self.state = null;
  }

  defer std.os.close(fd);

  const mapped = try std.os.mmap(null, size, std.os.PROT.READ, std.os.MAP.PRIVATE, fd, 0);
  defer std.os.munmap(mapped);

  const keymap = try (if (xkb.Keymap.newFromString(self.context, @ptrCast([*:0]const u8, mapped.ptr), .text_v1, .no_flags)) |value| value else error.BadKeymap);
  errdefer keymap.unref();
  self.keymap = keymap;

  const state = try (if (xkb.State.new(keymap)) |value| value else error.BadState);
  errdefer state.unref();
  self.state = state;
}

fn handleKey(self: *Self, keycode: u32, released: bool) !void {
  const compositor = self.getClient();
  const runtime = compositor.getRuntime();

  if (self.state == null) return;

  const keysym = self.state.?.keyGetOneSym(keycode);
  const unicode = self.state.?.keyGetUtf32(keycode);

  var message = std.ArrayList(u8).init(self.type.allocator);
  defer message.deinit();

  try std.json.stringify(.{
    .keymap = "linux",
    .toolkit = "gtk",
    .type = if (released) "keyup" 
      else "keydown",
    .keyCode = @enumToInt(keysym),
    .scanCode = keycode,
    .unicodeScalarValues = unicode,
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

fn listener(_: *wl.Keyboard, event: wl.Keyboard.Event, self: *Self) void {
  switch (event) {
    .keymap => |keymap| {
      self.updateKeymap(keymap.fd, keymap.size) catch |err| {
        std.debug.print("Failed to update the keymap: {s}\n", .{ @errorName(err) });
        return;
      };
    },
    .key => |key| {
      self.handleKey(key.key + 8, key.state == .released) catch |err| {
        std.debug.print("Failed to send key: {s}\n", .{ @errorName(err) });
        return;
      };
    },
    else => {},
  }
}

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    const context = try (xkb.Context.new(.no_flags) orelse error.OutOfMemory);
    context.setLogLevel(if (builtin.mode == .Debug) .debug else .err);

    self.* = .{
      .type = t,
      .value = params.value,
      .context = context,
      .base_keyboard = undefined,
      .keymap = null,
      .state = null,
    };

    _ = try Keyboard.init(&self.base_keyboard, .{
      .context = params.context,
    }, self, self.type.allocator);

    const client = self.getClient();

    self.value.setListener(*Self, listener, self);
    if (client.wl_display.roundtrip() != .SUCCESS) return error.RoundtripFail;
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .value = self.value,
      .context = self.context.ref(),
      .keymap = if (self.keymap) |keymap| keymap.ref() else null,
      .state = if (self.state) |state| state.ref() else null,
      .base_keyboard = undefined,
    };

    _ = try self.base_keyboard.type.refInit(&dest.base_keyboard, t.allocator);
  }

  pub fn unref(self: *Self) void {
    if (self.keymap) |keymap| {
      keymap.unref();
    }

    if (self.state) |state| {
      state.unref();
    }

    self.base_keyboard.unref();
    self.context.unref();
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
value: *wl.Keyboard,
keymap: ?*xkb.Keymap,
state: ?*xkb.State,
context: *xkb.Context,
base_keyboard: Keyboard,

pub usingnamespace Type.Impl;

pub fn getClient(self: *Self) *Client {
  return @fieldParentPtr(Client, "base_client", @fieldParentPtr(BaseClient, "context", self.base_keyboard.base.context));
}
