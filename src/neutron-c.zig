const std = @import("std");
const neutron = @import("neutron");

pub export const NEUTRON_HAS_GBM = neutron.config.has_gbm;
pub export const NEUTRON_VERSION_MAJOR = neutron.config.version.major;
