pub const c = @cImport({
  @cInclude("drm.h");
  @cInclude("errno.h");
  @cInclude("xf86drm.h");
  @cInclude("xf86drmMode.h");
});
