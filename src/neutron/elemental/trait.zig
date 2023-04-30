const std = @import("std");

fn indexOfNonAlphaNumPos(haystack: []const u8, start_index: usize) ?usize {
  const haystack_bytes = std.mem.sliceAsBytes(haystack);

  var i: usize = start_index * @sizeOf(u8);
  while (i < haystack_bytes.len) {
    const c = haystack_bytes[i];
    if (i % @sizeOf(u8) == 0 and !std.ascii.isAlphanumeric(c) and c != '.' and c != '-' and c != '_') {
      return @divExact(i, @sizeOf(u8));
    }

    i += 1;
  }
  return null;
}

pub fn getTypeName(value: anytype, inside: bool, allocator: std.mem.Allocator) []const u8 {
  const T = @TypeOf(value);
  if (comptime std.meta.trait.hasFn("getTypeName")(T)) {
    return allocator.dupe(u8, value.getTypeName(inside));
  }

  const str = @typeName(value);
  if (inside) {
    const offset = if (indexOfNonAlphaNumPos(str, 0)) |tmp| (tmp + 1) else 0;
    const end = indexOfNonAlphaNumPos(str, offset + 1) orelse str.len;
    const ret = allocator.alloc(u8, end - offset) catch @panic("out of memory");

    for (ret, str[offset..end]) |*v, c|
      v.* = c;

    return ret;
  } else {
    const end = indexOfNonAlphaNumPos(str, 0) orelse str.len;
    const ret = allocator.alloc(u8, end) catch @panic("out of memory");

    for (ret, str[0..end]) |*v, c|
      v.* = c;

    return ret;
  }
}
