#pragma once

#include <neutron/platform/device.h>
#include <systemd/sd-device.h>

/**
 * SECTION: systemd-device
 * @title: Systemd Device
 * @short_description: A device using systemd for Linux
 */

/**
 * NtSystemdDevice:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * A device using systemd for Linux
 */
typedef struct _NtSystemdDevice {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtSystemdDevicePrivate* priv;
} NtSystemdDevice;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_SYSTEMD_DEVICE:
 *
 * The %NtType ID of %NtSystemdDevice
 */
#define NT_TYPE_SYSTEMD_DEVICE nt_systemd_device_get_type()
NT_DECLARE_TYPE(NT, SYSTEMD_DEVICE, NtSystemdDevice, nt_systemd_device);

/**
 * nt_systemd_device_new:
 * @device: The systemd device
 *
 * Creates a new device which uses systemd's device API.
 *
 * Returns: A new device
 */
NtDevice* nt_systemd_device_new(sd_device* device);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
