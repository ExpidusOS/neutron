const std = @import("std");
const Reference = @import("ref.zig");

pub fn Type(comptime T: type, comptime P: type, comptime impl: anytype) type {
  return struct {
    const Self = @This();

    const ConstructFunc = fn (self: *T, params: P, t: Self) anyerror!void;
    const RefFunc = fn (self: *T, dest: *T, t: Self) anyerror!void;
    const UnrefFunc = fn (self: *T) void;
    const DestroyFunc = fn (self: *T) void;

    allocated: bool = false,
    allocator: std.mem.Allocator = std.heap.page_allocator,
    parent: ?*anyopaque = null,
    ref: Reference = .{},

    pub const Impl = struct {
      pub fn init(params: P, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !T {
        return Self.init(params, parent, allocator);
      }

      pub fn new(params: P, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*T {
        return Self.new(params, parent, allocator);
      }

      pub fn ref(self: *T, allocator: ?std.mem.Allocator) !*T {
        return Self.refNew(@constCast(&self.type), allocator);
      }

      pub fn unref(self: *T) void {
        return Self.unref(@constCast(&self.type));
      }
    };

    pub fn typeInit(parent: ?*anyopaque, allocator: ?std.mem.Allocator) !Self {
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
      return typeInit(parent, std.heap.page_allocator);
    }

    pub fn init(params: P, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !T {
      var type_inst = try typeInit(parent, allocator);

      var self: T = undefined;
      type_inst.ref.value = @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), &self));
      if (@hasDecl(impl, "construct")) {
        try @as(ConstructFunc, impl.construct)(&self, params, type_inst);
      } else {
        self = .{
          .type = type_inst,
        };
      }
      return self;
    }

    pub fn new(params: P, parent: ?*anyopaque, allocator: ?std.mem.Allocator) !*T {
      var type_inst = try typeInit(parent, allocator);

      const self = try type_inst.allocator.create(T);
      errdefer type_inst.allocator.destroy(self);

      type_inst.allocated = true;
      type_inst.ref.value = @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), self));

      if (@hasDecl(impl, "construct")) {
        try @as(ConstructFunc, impl.construct)(self, params, type_inst);
      } else {
        self.* = .{
          .type = type_inst,
        };
      }
      return self;
    }

    pub fn fromOpaque(op: *anyopaque) *T {
      return @ptrCast(*T, @alignCast(@alignOf(*T), op));
    }

    pub fn toOpaque(self: *Self) *anyopaque {
      return @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), self.getInstance()));
    }

    pub fn getInstance(self: *Self) *T {
      return @fieldParentPtr(T, "type", self);
    }

    pub fn refInit(self: *Self, allocator: ?std.mem.Allocator) !T {
      if (allocator) |alloc| {
        var ref_type = Self {
          .allocated = false,
          .allocator = alloc,
          .parent = self.parent,
          .ref = try self.ref.ref(),
        };

        var dest: T = undefined;
        ref_type.ref.value = @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), &dest));

        if (@hasDecl(impl, "ref")) {
          try @as(RefFunc, impl.ref)(self.getInstance(), &dest, ref_type);
        } else {
          dest = .{
            .type = ref_type,
          };
        }
        return dest;
      }
      return self.refInit(self.allocator);
    }

    pub fn refNew(self: *Self, allocator: ?std.mem.Allocator) !*T {
      if (allocator) |alloc| {
        const dest = try alloc.create(T);
        errdefer alloc.destroy(dest);

        var ref_type = Self {
          .allocated = false,
          .allocator = alloc,
          .parent = self.parent,
          .ref = try self.ref.ref(),
        };

        ref_type.ref.value = @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), dest));

        if (@hasDecl(impl, "ref")) {
          try @as(RefFunc, impl.ref)(self.getInstance(), dest, ref_type);
        } else {
          dest.* = .{
            .type = ref_type,
          };
        }
        return dest;
      }

      return self.refNew(self.allocator);
    }

    pub fn unref(self: *Self) void {
      self.ref.unref();

      if (@hasDecl(impl, "unref")) {
        @as(UnrefFunc, impl.unref)(self.getInstance());
      }

      if (self.ref.count == 0 and @hasDecl(impl, "destroy")) {
        @as(DestroyFunc, impl.destroy)(self.getInstance());
      }

      if (self.allocated) {
        self.allocator.destroy(self);
      }
    }
  };
}
