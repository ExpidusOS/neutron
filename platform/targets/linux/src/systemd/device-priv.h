#pragma once

#include <neutron/platform/systemd-device.h>

typedef struct _NtSystemdDevicePrivate {
  sd_device* device;
} NtSystemdDevicePrivate;
