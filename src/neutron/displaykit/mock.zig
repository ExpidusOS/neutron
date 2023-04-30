const std = @import("std");
const base = @import("base.zig");

pub fn Mock(comptime name: []const u8) type {
  return struct {
    fn panic() void {
      @panic("DisplayKit backend " ++ name ++ " is not available.");
    }

    pub const Params = struct {
      base: base.Params,

      pub fn init() Params {
        return .{
          .base = .{
            .type = .client,
          },
        };
      }

      pub fn parseArgument(arg: []const u8) !Params {
        return .{
          .base = try base.Params.parseArgument(arg),
        };
      }
    };

    pub const Backend = union(base.Type) {
      client: void,
      compositor: void,

      pub fn init(params: Params, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Backend {
        _ = params;
        _ = parent;
        _ = allocator;
        panic();
      }

      pub fn ref(self: *Backend, allocator: ?std.mem.Allocator) !Backend {
        _ = self;
        _ = allocator;
        panic();
      }

      pub fn unref(self: *Backend) void {
        _ = self;
        panic();
      }
      
      pub fn toBase(self: *Backend) base.Backend {
        _ = self;
        panic();
      }
    };
  };
}
