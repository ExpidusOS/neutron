const config = @import("neutron-config");

pub const available = config.use_wlroots;

pub const Compositor = if (available) @import("wlroots/compositor.zig").WlrootsCompositor else null;
