#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: device
 * @section_id: device
 * @title: Device
 * @short_description: A hardware device
 */

/**
 * NtDevice:
 * @instance: An %NtTypeInstance associated with this
 *
 * A hardware device
 */
typedef struct _NtDevice {
  NtTypeInstance instance;
} NtDevice;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif


/**
 * NT_TYPE_DEVICE:
 *
 * The %NtType ID of %NtDevice
 */
#define NT_TYPE_DEVICE nt_device_get_type()
NT_DECLARE_TYPE(NT, DEVICE, NtDevice, nt_device);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
