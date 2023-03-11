const object = @import("object.zig");

pub const ValueData = union {
  object_type: object.ObjectType,
  object: *opaque {},
  string: []u8,
  int: i64,
  float: f64,
  boolean: bool
};

pub const ValueType = enum {
  object_type,
  object,
  string,
  int,
  float,
  boolean
};
