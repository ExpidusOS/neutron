#pragma once

#include <neutron/platform/systemd-device-enum.h>

typedef struct _NtSystemdDeviceEnumPrivate {
  sd_device_monitor* monitor;
} NtSystemdDeviceEnumPrivate;
