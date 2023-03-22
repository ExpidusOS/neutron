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

fn getTypeName(value: anytype, inside: bool) []const u8 {
  const T = @TypeOf(value);
  const allocator = std.heap.page_allocator;

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

pub fn json(value: anytype, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
  const T = @TypeOf(value);

  switch (@typeInfo(T)) {
    .ComptimeInt, .Int, .ComptimeFloat, .Float => return std.fmt.format(writer, "{}", .{ value }),
    .Bool => return std.fmt.formatBuf(if (value) "true" else "false", options, writer),
    .Struct => |info| {
      const type_name = getTypeName(T, true);
      defer std.heap.page_allocator.free(type_name);

      try writer.writeAll("{\"");
      try writer.writeAll(type_name);
      try writer.writeAll("\": {");

      inline for (info.fields, 0..) |f, i| {
        const is_last = i + 1 == info.fields.len;

        try writer.writeAll("\"");
        try writer.writeAll(f.name);
        try writer.writeAll("\": ");

        try json(@field(value, f.name), fmt, options, writer);

        if (!is_last) {
          try writer.writeAll(",");
        }
      }

      try writer.writeAll("} }");
    },
    .Pointer => |ptr_info| switch (ptr_info.size) {
      .One => switch (@typeInfo(ptr_info.child)) {
        .Array => |info| {
          if (info.child == u8) {
            return std.fmt.format(writer, "\"{s}\"", .{ value });
          }

          std.fmt.invalidFmtError(fmt, value);
        },
        .Enum, .Union, .Struct => {
          const type_name = getTypeName(ptr_info.child, false);
          defer std.heap.page_allocator.free(type_name);

          try writer.writeAll("{\"");
          try writer.writeAll(type_name);
          try writer.writeAll("\": ");
          try json(value.*, fmt, options, writer);
          try writer.writeAll("}");
        },
        else => {
          try writer.writeAll("{\"type\": \"");
          try writer.writeAll(@typeName(ptr_info.child));
          try writer.writeAll("\", \"value\": ");
          try std.fmt.format(writer, "{}", .{ @ptrToInt(value) });
          try writer.writeAll("}");
        },
      },
      .Many, .C => {
        if (ptr_info.sentinel) |_| {
          return json(std.mem.span(value), fmt, options, writer);
        }

        if (ptr_info.child == u8) {
          return std.fmt.format(writer, "\"{s}\"", .{ value });
        }

        std.fmt.invalidFmtError(fmt, value);
      },
      .Slice => {
        if (ptr_info.child == u8) {
          return std.fmt.format(writer, "\"{s}\"", .{ value });
        }

        try writer.writeAll("[");

        for (value, 0..) |elem, i| {
          const is_last = i + 1 == value.len;

          try json(elem, fmt, options, writer);

          if (!is_last) {
            try writer.writeAll(",");
          }
        }

        try writer.writeAll("]");
      },
    },
    .Array => |info| {
      if (info.child == u8) {
        return std.fmt.format(writer, "\"{s}\"", .{ value });
      }

      try writer.writeAll("[");

      for (value, 0..) |elem, i| {
        const is_last = i + 1 == value.len;

        try json(elem, fmt, options, writer);

        if (!is_last) {
          try writer.writeAll(",");
        }
      }

      try writer.writeAll("]");
    },
    .Vector => |info| {
      try writer.writeAll("[");

      var i: usize = 0;
      while (i < info.len) : (i += 1) {
        const is_last = i + 1 == info.len;

        try json(value[i], fmt, options, writer);

        if (!is_last) {
          try writer.writeAll(",");
        }
      }

      try writer.writeAll("]");
    },
    .Optional => {
      if (value) |payload| {
        return json(payload, fmt, options, writer);
      } else {
        return writer.writeAll("null");
      }
    },
    .Null => return writer.writeAll("null"),
    else => @compileError("Unable to format type '" ++ @typeName(T) ++ "'"),
  }
}
