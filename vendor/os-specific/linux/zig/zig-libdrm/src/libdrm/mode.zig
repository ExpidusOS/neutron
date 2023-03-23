const std = @import("std");
const c = @import("../c.zig").c;
const utils = @import("../utils.zig");
const Mode = @This();

pub const Sync = struct {
  start: u16,
  end: u16,

  pub fn getTotal(self: Sync) u16 {
    return self.end - self.start;
  }

  pub fn format(self: Sync, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    return std.fmt.format(writer, "{} - {} ({})", .{ self.start, self.end, self.getTotal() });
  }
};

pub const Axis = struct {
  value: u16,
  total: u16,
  sync: Sync,

  pub fn init(info: c.drmModeModeInfoPtr, comptime side: []const u8) Axis {
    return .{
      .value = @field(info.*, side ++ "display"),
      .total = @field(info.*, side ++ "total"),
      .sync = .{
        .start = @field(info.*, side ++ "sync_start"),
        .end = @field(info.*, side ++ "sync_end"),
      },
    };
  }
};

clock: u32,
horizontal: Axis,
vertical: Axis,
hskew: u16,
vscan: u16,
vrefresh: u32,
flags: u32,
@"type": u32,
name: [c.DRM_DISPLAY_MODE_LEN]u8,

pub fn init(info: c.drmModeModeInfoPtr) Mode {
  return .{
    .clock = info.*.clock,
    .horizontal = Axis.init(info, "h"),
    .vertical = Axis.init(info, "v"),
    .hskew = info.*.hskew,
    .vscan = info.*.vscan,
    .vrefresh = info.*.vrefresh,
    .flags = info.*.flags,
    .type = info.*.type,
    .name = info.*.name,
  };
}

pub fn getRefreshRate(self: Mode) i32 {
  var refresh = (self.clock * 1000000 / self.horizontal.total + self.vertical.total / 2) / self.vertical.total;

  if (self.vscan > 1) {
    refresh /= self.vscan;
  }
}

pub fn @"export"(self: Mode) c.drmModeModeInfo {
  return .{
    .clock = self.clock,
    .hdisplay = self.horizontal.value,
    .hsync_start = self.horizontal.sync.start,
    .hsync_end = self.horizontal.sync.end,
    .htotal = self.horizontal.total,
    .vdisplay = self.vertical.value,
    .vsync_start = self.vertical.sync.start,
    .vsync_end = self.vertical.sync.end,
    .vtotal = self.vertical.total,
    .hskew = self.hskew,
    .vscan = self.vscan,
    .vrefresh = self.vrefresh,
    .flags = self.flags,
    .type = self.type,
    .name = self.name,
  };
}
