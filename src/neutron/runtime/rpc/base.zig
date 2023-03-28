const std = @import("std");
const rpc = @import("antiphony");
const elemental = @import("../../elemental.zig");
const Runtime = @import("../runtime.zig");
const config = @import("neutron-config");

pub const Definition = rpc.CreateDefinition(.{
  .host = .{
    .getVersion = fn () std.builtin.Version,
    .getVersionCompatibility = fn () std.builtin.Version.Range,
    .isVersionCompatible = fn (std.builtin.Version) bool,
  },
  .client = .{},
});

pub const TypeOf = enum {
  client,
  host,
};

pub fn Implementation(comptime Reader: type, comptime Writer: type) type {
  return struct {
    pub const Host = struct {
      const Self = @This();

      pub const EndPoint = Definition.HostEndPoint(Reader, Writer, Self);

      pub const Params = struct {
        runtime: *Runtime,
        endpoint: EndPoint,
      };

      pub const TypeInfo = elemental.TypeInfo {
        .init = impl_init,
        .construct = impl_construct,
        .destroy = impl_destroy,
        .dupe = impl_dupe,
      };

      /// Neutron's Elemental type definition
      pub const Type = elemental.Type(Self, Params, TypeInfo);

      endpoint: EndPoint,
      runtime: *Runtime,

      fn impl_init(_params: *anyopaque, _: std.mem.Allocator) !*anyopaque {
        const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
        return &(Self {
          .runtime = params.runtime.ref(),
          .endpoint = params.endpoint,
        });
      }

      fn impl_construct(_self: *anyopaque, _: *anyopaque) !void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
        try self.endpoint.connect(self);
      }

      fn impl_destroy(_self: *anyopaque) !void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
        self.endpoint.destroy();
        self.runtime.unref();
      }

      fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
        const dest = @ptrCast(*Self, @alignCast(@alignOf(Self), _dest));

        dest.endpoint = self.endpoint;
        dest.runtime = self.runtime.ref();
      }

      pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Self {
        return &(try Type.new(params, allocator)).instance;
      }

      pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
        return try Type.init(params, allocator);
      }

      /// Gets the Elemental type definition instance for this instance
      pub fn getType(self: *Self) *Type {
        return @fieldParentPtr(Type, "instance", self);
      }

      /// Increases the reference count and return the instance
      pub fn ref(self: *Self) *Self {
        return &(self.getType().ref().instance);
      }

      /// Decreases the reference count and free it if the counter is 0
      pub fn unref(self: *Self) void {
        return self.getType().unref();
      }

      pub fn dupe(self: *Self, allocator: ?std.mem.Allocator) !*Self {
        return &(try self.getType().dupe(allocator)).instance;
      }

      pub fn getVersion(_: *Self) std.builtin.Version {
        return config.version;
      }

      pub fn getVersionCompatibility(self: *Self) std.builtin.Version.Range {
        return .{
          .min = self.getVersion(),
          .max = config.version,
        };
      }

      pub fn isVersionCompatible(self: *Self, ver: std.builtin.Version) bool {
        return self.getVersionCompatibility().isAtLeast(ver) == true;
      }
    };

    pub const Client = struct {
      const Self = @This();

      pub const EndPoint = Definition.ClientEndPoint(Reader, Writer, Self);

      pub const Params = struct {
        endpoint: EndPoint,
        runtime: *Runtime,
      };

      pub const TypeInfo = elemental.TypeInfo {
        .init = impl_init,
        .construct = impl_construct,
        .destroy = impl_destroy,
        .dupe = impl_dupe,
      };

      /// Neutron's Elemental type definition
      pub const Type = elemental.Type(Self, Params, TypeInfo);

      endpoint: EndPoint,
      runtime: *Runtime,

      fn impl_init(_params: *anyopaque, _: std.mem.Allocator) !*anyopaque {
        const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
        return &(Self {
          .endpoint = params.endpoint,
          .runtime = params.runtime.ref(),
        });
      }

      fn impl_construct(_self: *anyopaque, _: *anyopaque) !void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
        try self.endpoint.connect(self);
      }

      fn impl_destroy(_self: *anyopaque) !void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
        self.endpoint.destroy();
        self.runtime.unref();
      }

      fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
        const dest = @ptrCast(*Self, @alignCast(@alignOf(Self), _dest));

        dest.endpoint = self.endpoint;
        dest.runtime = self.runtime.ref();
      }

      pub fn new(params: Params, allocator: ?std.mem.Allocator) !*Self {
        return &(try Type.new(params, allocator)).instance;
      }

      pub fn init(params: Params, allocator: ?std.mem.Allocator) !Type {
        return try Type.init(params, allocator);
      }

      /// Gets the Elemental type definition instance for this instance
      pub fn getType(self: *Self) *Type {
        return @fieldParentPtr(Type, "instance", self);
      }

      /// Increases the reference count and return the instance
      pub fn ref(self: *Self) *Self {
        return &(self.getType().ref().instance);
      }

      /// Decreases the reference count and free it if the counter is 0
      pub fn unref(self: *Self) void {
        return self.getType().unref();
      }

      pub fn dupe(self: *Self, allocator: ?std.mem.Allocator) !*Self {
        return &(try self.getType().dupe(allocator)).instance;
      }
    };

    pub const OneOf = union(TypeOf) {
      client: *Client,
      host: *Host,

      pub fn new(t: TypeOf, params: *anyopaque, allocator: ?std.mem.Allocator) !OneOf {
        return switch (t) {
          .client => .{
            .client = try Client.new(params, allocator),
          },
          .host => .{
            .host = try Host.new(params, allocator),
          },
        };
      }

      pub fn getType(self: OneOf) TypeOf {
        return switch (self) {
          .client => .client,
          .host => .host,
        };
      }
    };
  };
}
