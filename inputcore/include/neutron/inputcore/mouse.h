#pragma once

#include <neutron/elemental.h>
#include <neutron/inputcore/device.h>

/**
 * SECTION: mouse
 * @title: Mouse Input
 * @short_description: A mouse input device
 */

/**
 * NtMouseInput:
 * @instance: The %NtTypeInstance associated with this
 * @see_also: %NtInputDevice
 *
 * A mouse input device
 */
typedef struct _NtMouseInput {
  NtTypeInstance instance;
} NtMouseInput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_MOUSE_INPUT:
 *
 * The %NtType for %NtMouseInput
 */
#define NT_TYPE_MOUSE_INPUT nt_mouse_input_get_type()
NT_DECLARE_TYPE(NT, MOUSE_INPUT, NtMouseInput, nt_mouse_input);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
