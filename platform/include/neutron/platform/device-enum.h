#pragma once

#include <neutron/elemental.h>
#include <neutron/platform/device.h>

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
 * @count: Method for counting a query
 * @query: Method for performing a query
 *
 * Enumerator for hardware devices
 */
typedef struct _NtDeviceEnum {
  NtTypeInstance instance;

  NtSignal* added;
  NtSignal* removed;

  size_t (*count)(struct _NtDeviceEnum* self, NtDeviceQuery query);
  NtList* (*query)(struct _NtDeviceEnum* self, NtDeviceQuery query);
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
 * nt_device_enum_count:
 * @self: The %NtDeviceEnum instance
 * @query: The query to use
 *
 * Queries all devices and returns the number of devices discovered for a given query
 *
 * Returns: The number of devices
 */
size_t nt_device_enum_count(NtDeviceEnum* self, NtDeviceQuery query);

/**
 * nt_device_enum_query:
 * @self: The %NtDeviceEnum instance
 * @query: The query to use
 *
 * Queries all devices
 *
 * Returns: An %NtList holding %NtDevice
 */
NtList* nt_device_enum_query(NtDeviceEnum* self, NtDeviceQuery query);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
