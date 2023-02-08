#pragma once

#include <neutron/platform/device-enum.h>
#include <systemd/sd-device.h>

/**
 * SECTION: systemd-device-enum
 * @title: Systemd Device Enumerator
 * @short_description: A device enumerator using systemd for Linux
 */

/**
 * NtSystemdDeviceEnum:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * A device enumerator using systemd for Linux
 */
typedef struct _NtSystemdDeviceEnum {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtSystemdDeviceEnumPrivate* priv;
} NtSystemdDeviceEnum;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_SYSTEMD_DEVICE_ENUM:
 *
 * The %NtType ID of %NtSystemdDeviceEnum
 */
#define NT_TYPE_SYSTEMD_DEVICE_ENUM nt_systemd_device_enum_get_type()
NT_DECLARE_TYPE(NT, SYSTEMD_DEVICE_ENUM, NtSystemdDeviceEnum, nt_systemd_device_enum);

/**
 * nt_systemd_device_enum_new:
 *
 * Creates a new device enumerator which uses systemd's device API.
 *
 * Returns: A new device enumerator
 */
NtDeviceEnum* nt_systemd_device_enum_new();

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
