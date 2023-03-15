const std = @import("std");
const _type = @import("type.zig");

pub fn TypedList(comptime T: type, comptime P: type, comptime info: _type.TypeInfo(T)) type {
  return AlignedTypedList(T, P, info, null);
}

/// Define a new typed list
pub fn AlignedTypedList(comptime T: type, comptime P: type, comptime info: _type.TypeInfo(T), comptime alignment: ?u29) type {
  return struct {
    const Self = @This();

    pub const Params = struct {
      list: ?ArrayList,
    };

    /// Neutron's Elemental type information for items
    pub const ItemTypeInfo = info;

    /// Neutron's Elemental type definition for items
    pub const ItemType = _type.Type(T, P, info);

    /// Neutron's Elemental type information
    pub const TypeInfo = _type.TypeInfo(Self) {
      .init = impl_init,
      .construct = null,
      .destroy = destroy,
      .dupe = impl_dupe,
    };

    /// Neutron's Elemental type definition
    pub const Type = _type.Type(Self, Params, TypeInfo);

    pub const ArrayList = std.ArrayListAligned(*ItemType, alignment);

    list: ArrayList,

    /// Creates a new instance of a typed list
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

    pub fn dupe(self: *Self) !*Self {
      return &(try self.getType().dupe()).instance;
    }

    pub fn first(self: *Self) ?*ItemType {
      return self.item(0);
    }

    pub fn last(self: *Self) ?*ItemType {
      return self.item(self.list.items.len - 1);
    }

    pub fn item(self: *Self, index: usize) ?*ItemType {
      if (self.list.items.len > index) return null;
      return self.list.items[index].ref();
    }

    fn impl_init(_params: *anyopaque, allocator: std.mem.Allocator) !Self {
      const params = @ptrCast(*Params, @alignCast(@alignOf(Params), _params));
      return .{
        .list = if (params.list != null) params.list.? else ArrayList.init(allocator),
      };
    }

    fn destroy(_self: *anyopaque) void {
      const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));

      var _item = self.list.popOrNull();
      while (_item != null) {
        _item.?.unref();
        _item = self.list.popOrNull();
      }

      self.list.deinit();
    }

    fn impl_dupe(_self: *anyopaque, _dest: *anyopaque) !void {
      const self = @ptrCast(*Self, @alignCast(@alignOf(Self), _self));
      const dest = @ptrCast(*Self, @alignCast(@alignOf(Self), _dest));

      dest.list = ArrayList.init(dest.getType().allocator);
      for (self.list.items) |_item| {
        try dest.list.append(_item.ref());
      }
    }
  };
}
