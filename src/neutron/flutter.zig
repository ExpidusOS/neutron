const std = @import("std");

pub const MethodChannel = @import("flutter/method-channel.zig");
pub const MethodChannels = std.StringHashMap(*MethodChannel);

pub const c = @cImport({
  @cInclude("flutter_embedder.h");
});
