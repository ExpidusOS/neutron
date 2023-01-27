#pragma once

#include <neutron/platform/platform.h>

typedef struct _NtPlatformPrivate {
  NtDeviceEnum* device_enum;
} NtPlatformPrivate;
