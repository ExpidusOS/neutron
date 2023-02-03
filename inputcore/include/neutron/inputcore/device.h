#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: device
 * @title: Device
 * @short_description: A basic type for all input devices
 */

/**
 * NtInputDevice:
 * @instance: The %NtTypeInstance associated with this
 *
 * A basic type for all input devices
 */
typedef struct _NtInputDevice {
  NtTypeInstance instance;
} NtInputDevice;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_INPUT_DEVICE:
 *
 * The %NtType for %NtInputDevice
 */
#define NT_TYPE_INPUT_DEVICE nt_input_device_get_type()
NT_DECLARE_TYPE(NT, INPUT_DEVICE, NtInputDevice, nt_input_device);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
