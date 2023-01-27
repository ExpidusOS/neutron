#pragma once

#include <neutron/elemental.h>

NT_BEGIN_DECLS

typedef struct _NtDeviceEnum {
  NtTypeInstance instance;

  size_t (*get_device_count)(struct _NtDeviceEnum* self);
} NtDeviceEnum;

#define NT_TYPE_DEVICE_ENUM nt_device_enum_get_type()
NT_DECLARE_TYPE(NT, DEVICE_ENUM, NtDeviceEnum, nt_device_enum);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_device_enum_get_device_count:
 *
 * Counts the number of devices which have been discovered.
 */
size_t nt_device_enum_get_device_count(NtDeviceEnum* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
