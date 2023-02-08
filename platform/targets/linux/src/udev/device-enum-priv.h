#pragma once

#include <neutron/platform/udev-device-enum.h>

typedef struct _NtUdevDeviceEnumPrivate {
  struct udev* udev;
} NtUdevDeviceEnumPrivate;
