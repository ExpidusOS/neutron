#pragma once

#include <neutron/elemental.h>
#include <neutron/inputcore/device.h>

/**
 * SECTION: touch
 * @title: Touch Input
 * @short_description: A touch input device
 */

/**
 * NtTouchInput:
 * @instance: The %NtTypeInstance associated with this
 * @see_also: %NtInputDevice
 *
 * A touch input device
 */
typedef struct _NtTouchInput {
  NtTypeInstance instance;
} NtTouchInput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_TOUCH_INPUT:
 *
 * The %NtType for %NtTouchInput
 */
#define NT_TYPE_TOUCH_INPUT nt_touch_input_get_type()
NT_DECLARE_TYPE(NT, TOUCH_INPUT, NtTouchInput, nt_touch_input);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
