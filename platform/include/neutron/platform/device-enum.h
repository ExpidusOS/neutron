#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: device-enum
 * @section_id: device-enum
 * @title: Device Enumerator
 * @short_description: Enumeration of devices on the platform
 */

/**
 * NtDeviceEnum:
 * @instance: An %NtTypeInstance associated with this
 * @added: Signal for when devices are added
 * @removed: Signal for when devices are removed
 * @get_device_count: Method for counting the number of devices
 *
 * Enumerator for hardware devices
 */
typedef struct _NtDeviceEnum {
  NtTypeInstance instance;

  NtSignal* added;
  NtSignal* removed;

  size_t (*get_device_count)(struct _NtDeviceEnum* self);
} NtDeviceEnum;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DEVICE_ENUM:
 *
 * The %NtType ID of %NtDeviceEnum
 */
#define NT_TYPE_DEVICE_ENUM nt_device_enum_get_type()
NT_DECLARE_TYPE(NT, DEVICE_ENUM, NtDeviceEnum, nt_device_enum);

/**
 * nt_device_enum_get_device_count:
 * @self: The %NtDeviceEnum instance
 *
 * Counts the number of devices which have been discovered.
 * Returns: The number of devices
 */
size_t nt_device_enum_get_device_count(NtDeviceEnum* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
