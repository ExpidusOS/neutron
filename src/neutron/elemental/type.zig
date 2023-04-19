const std = @import("std");
const Reference = @import("ref.zig");

pub fn Type(comptime T: type, comptime P: type, comptime impl: anytype) type {
  return struct {
    const Self = @This();

    const ConstructFunc = fn (self: *T, params: P, t: Self) anyerror!void;
    const RefFunc = fn (self: *T, dest: *T, t: Self) anyerror!void;
    const UnrefFunc = fn (self: *T) void;
    const DestroyFunc = fn (self: *T) void;

    pub const ParentType = struct {
      name: []const u8,
      field: ?[]const u8,
      offset: ?usize,
      ptr: *anyopaque,

      pub fn init(value: anytype) ParentType {
        const field: ?[]const u8 = comptime blk: {
          inline for (std.meta.fields(@TypeOf(value.*))) |f| {
            if (f.type == T) {
              break :blk f.name;
            }
          }
          break :blk null;
        };

        return .{
          .name = @typeName(@TypeOf(value)),
          .field = field,
          .offset = if (field) |f| @offsetOf(@TypeOf(value.*), f) else null,
          .ptr = @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), value)),
        };
      }

      pub fn format(self: ParentType, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;

        try writer.writeAll(self.name);
        try writer.writeByte('@');

        if (self.field != null and self.offset != null) {
          try writer.print("{s}:{}=", .{ self.field.?, self.offset.? });
        }

        try writer.print("{x}", .{ @ptrToInt(self.ptr) });
      }
    };

    pub const Parent = union(enum) {
      ty: ParentType,
      op: *anyopaque,

      pub fn init(value: anytype) ?Parent {
        const t = @typeInfo(@TypeOf(value));

        if (t == .Null or t == .Undefined) return null;
        if (t == .Optional) return if (value) |v| Parent.init(v) else null;
        if (t != .Pointer) @compileError("Must be a pointer");

        return switch (@typeInfo(t.Pointer.child)) {
          .Opaque => .{
            .op = value,
          },
          .Struct => .{
            .ty = ParentType.init(value),
          },
          else => @compileError("Invalid type " ++ @tagName(@typeInfo(t.Pointer.child))),
        };
      }

      pub fn getValue(self: *Parent) *anyopaque {
        return switch (self.*) {
          .ty => |t| t.ptr,
          .op => |o| o,
        };
      }

      pub fn format(self: Parent, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        return switch (self) {
          .ty => |t| t.format(fmt, options, writer),
          .op => |o| writer.print("{x}", .{ @ptrToInt(o) }),
        };
      }
    };

    allocated: bool = false,
    allocator: std.mem.Allocator = std.heap.page_allocator,
    parent: ?Parent = null,
    ref: Reference = .{},

    pub const Impl = struct {
      pub fn init(params: P, parent: anytype, allocator: ?std.mem.Allocator) !T {
        return Self.init(params, parent, allocator);
      }

      pub fn new(params: P, parent: anytype, allocator: ?std.mem.Allocator) !*T {
        return Self.new(params, parent, allocator);
      }

      pub fn ref(self: *T, allocator: ?std.mem.Allocator) !*T {
        return Self.refNew(@constCast(&self.type), allocator);
      }

      pub fn unref(self: *T) void {
        return Self.unref(@constCast(&self.type));
      }
    };

    pub fn typeInit(parent: anytype, allocator: ?std.mem.Allocator) !Self {
      if (allocator) |alloc| {
        var self = Self {
          .allocated = false,
          .allocator = alloc,
          .parent = Parent.init(parent),
          .ref = .{},
        };
        return self;
      }
      return typeInit(parent, std.heap.page_allocator);
    }

    pub fn init(params: P, parent: anytype, allocator: ?std.mem.Allocator) !T {
      var type_inst = try typeInit(parent, allocator);

      var self: T = undefined;
      if (@hasDecl(impl, "construct")) {
        try @as(ConstructFunc, impl.construct)(&self, params, type_inst);
      } else {
        self = .{
          .type = type_inst,
        };
      }
      return self;
    }

    pub fn new(params: P, parent: anytype, allocator: ?std.mem.Allocator) !*T {
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
      return self.ref.value orelse @ptrCast(*anyopaque, @alignCast(@alignOf(*anyopaque), self.getInstance()));
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

        if (self.allocated) return error.MustAllocate;

        var dest: T = undefined;
        ref_type.ref.value = null;

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
          .allocated = true,
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
