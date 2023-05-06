const std = @import("std");
const elemental = @import("../elemental.zig");
const MethodCodec = @import("method-codec.zig");

pub const Params = struct {
  name: []const u8,
  codec: *MethodCodec,
};
