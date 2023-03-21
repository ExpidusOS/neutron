const config = @import("neutron-config");
const std = @import("std");

pub const Type = enum {
  auto,
  wayland
};

pub const Error = error {
  UnsupportedBackend,
  InvalidBackend,
  NoBackends
};

const BackendEntry = struct {
  name: []const u8,
  enabled: bool = true,
  value: type,
};

const backends = [_]BackendEntry {
  BackendEntry {
    .name = "wayland",
    .enabled = config.use_wayland,
    .value = @import("backends/wayland.zig"),
  }
};

pub fn get(comptime t: Type) Error!type {
  if (t == .auto) {
    for (backends) |backend| {
      if (backend.enabled) return backend.value;
    }

    return Error.NoBackends;
  }

  for (backends) |backend| {
    if (std.mem.eql(u8, @tagName(t), backend.name)) {
      if (backend.enabled) return backend.value;
      return Error.UnsupportedBackend;
    }
  }
  return Error.InvalidBackend;
}
