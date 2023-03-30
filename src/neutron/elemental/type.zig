const std = @import("std");
const Reference = @import("ref.zig");

pub fn Type(comptime T: type, comptime P: type, comptime impl: anytype) type {
  return struct {
    const Self = @This();

    const RefFunc = fn (self: *T, t: Self) anyerror!T;
    const UnrefFunc = fn (self: *T) anyerror!void;

    allocated: bool,
    allocator: std.mem.Allocator,
    parent: ?*anyopaque,
    ref: Reference,

    pub fn init(parent: ?*anyopaque, allocator: ?std.mem.Allocator) Self {
      if (allocator) |alloc| {
        var self = Self {
          .allocated = false,
          .allocator = alloc,
          .parent = parent,
          .ref = .{},
        };

        self.ref.value = &self;
        return self;
      }
      return Self.init(parent, std.heap.page_allocator);
    }

    pub fn new(params: P, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*T {
      const type_inst = Self.init(parent, allocator);

      const self = try type_inst.allocator.create(T);
      errdefer type_inst.allocator.destroy(self);

      if (@hasDecl(T, "init")) {
        self.* = try T.init(params, parent, allocator);
      }

      self.type = type_inst;
      self.type.allocated = true;
      return self;
    }

    pub fn getInstance(self: *Self) *T {
      return @fieldParentPtr(T, "type", self);
    }

    pub fn refInit(self: *Self, allocator: ?std.mem.Allocator) !T {
      if (allocator) |alloc| {
        const ref_type = Self {
          .allocated = false,
          .allocator = alloc,
          .parent = self.parent,
          .ref = try self.ref.ref(),
        };

        return if (@hasDecl(impl, "ref"))
          try @as(RefFunc, impl.ref)(self.getInstance(), ref_type)
        else
          T {
            .type = ref_type,
          };
      }
      return self.refInit(self.allocator);
    }

    pub fn refNew(self: *Self, allocator: ?std.mem.Allocator) !*T {
      if (allocator) |alloc| {
        const self_ref = try alloc.create(T);
        errdefer alloc.destroy(self_ref);

        self_ref.* = try self.refInit(alloc);
        self_ref.type.allocated = true;
        return self_ref;
      }

      return self.refNew(self.allocator);
    }

    pub fn unref(self: *Self) !void {
      try self.ref.unref();

      if (@hasDecl(impl, "unref")) {
        try @as(UnrefFunc, impl.unref)(self.getInstance());
      }

      if (self.allocated) {
        self.allocator.destroy(self);
      }
    }
  };
}
