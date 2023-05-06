pub fn MethodCall(comptime T: type) type {
  return struct {
    const Self = @This();

    arguments: T,
    method: []const u8,

    pub fn init(method: []const u8, arguments: T) Self {
      return .{
        .method = method,
        .arguments = arguments,
      };
    }
  };
}
