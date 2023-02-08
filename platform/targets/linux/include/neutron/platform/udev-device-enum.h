#pragma once

#include <neutron/platform/device-enum.h>
#include <libudev.h>

/**
 * SECTION: udev-device-enum
 * @title: Udev Device Enumerator
 * @short_description: A device enumerator using udev
 */

/**
 * NtUdevDeviceEnum:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * A device enumerator using udev
 */
typedef struct _NtUdevDeviceEnum {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtUdevDeviceEnumPrivate* priv;
} NtUdevDeviceEnum;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_UDEV_DEVICE_ENUM:
 *
 * The %NtType ID of %NtUdevDeviceEnum
 */
#define NT_TYPE_UDEV_DEVICE_ENUM nt_udev_device_enum_get_type()
NT_DECLARE_TYPE(NT, UDEV_DEVICE_ENUM, NtUdevDeviceEnum, nt_udev_device_enum);

NtDeviceEnum* nt_udev_device_enum_new();

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
