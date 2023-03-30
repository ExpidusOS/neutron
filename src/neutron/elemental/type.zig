const std = @import("std");
const Reference = @import("ref.zig");

pub fn Type(comptime T: type, comptime P: type, comptime impl: anytype) type {
  return struct {
    const Self = @This();

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

    pub fn refInit(self: *Self, allocator: ?std.mem.Allocator) !Self {
      if (allocator) |alloc| {
        return Self {
          .allocated = false,
          .allocator = alloc,
          .parent = self.parent,
          .ref = try self.ref.ref(),
        };
      }
      return self.refInit(self.allocator);
    }

    pub fn refNew(self: *Self, allocator: ?std.mem.Allocator) !*Self {
      if (allocator) |alloc| {
        const ref_type = try self.refInit(alloc);
        errdefer ref_type.ref.unref();

        const self_ref = try ref_type.allocator.create(T);
        errdefer ref_type.allocator.destroy(self_ref);

        ref_type.allocated = true;

        if (@hasDecl(impl, "ref")) {
          self_ref.* = try impl.ref(self.getInstance(), ref_type);
        }

        self_ref.type = ref_type;
        self_ref.type.allocated = true;
        return true;
      }

      return self.refNew(self.allocator);
    }

    pub fn unref(self: *Self) !void {
      try self.ref.unref();

      if (@hasDecl(impl, "unref")) {
        try impl.unref(self.getInstance());
      }

      if (self.allocated) {
        self.allocator.destroy(self);
      }
    }
  };
}
