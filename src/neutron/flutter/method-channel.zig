const elemental = @import("../elemental.zig");
const Self = @This();

pub const HandlerMethod = *const fn (channel: *Self, data: []const u8, ud: ?*anyopaque) anyerror![]u8;

pub const Handler = struct {
  method: HandlerMethod,
  userdata: ?*anyopaque,
};

pub const Params = struct {
  name: []const u8,
  handler: ?Handler,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    self.* = .{
      .type = t,
      .name = params.name,
      .handler = params.handler,
    };
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .name = self.name,
      .handler = self.handler,
    };
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
name: []const u8,
handler: ?Handler,

pub usingnamespace Type.Impl;

pub fn setMethodCallHandler(self: *Self, method: HandlerMethod, userdata: ?*anyopaque) void {
  self.handler = .{
    .method = method,
    .userdata = userdata
  };
}

pub fn receive(self: *Self, data: []const u8) anyerror!?[]u8 {
  if (self.handler) |handler| {
    return try handler.method(self, data, handler.userdata);
  }
  return null;
}
