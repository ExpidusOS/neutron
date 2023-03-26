const std = @import("std");
const elemental = @import("../../../../elemental.zig");
const rpc = @import("../../base.zig");

pub const Implementation = rpc.Implementation(std.net.Stream.Reader, std.net.Stream.Writer);
