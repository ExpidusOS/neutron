#pragma once

#include <neutron/elemental.h>
#include <neutron/inputcore/device.h>

/**
 * SECTION: keyboard
 * @title: Keyboard Input
 * @short_description: A keyboard input device
 */

/**
 * NtKeyboardInput:
 * @instance: The %NtTypeInstance associated with this
 * @see_also: %NtInputDevice
 *
 * A keyboard input device
 */
typedef struct _NtKeyboardInput {
  NtTypeInstance instance;
} NtKeyboardInput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_KEYBOARD_INPUT:
 *
 * The %NtType for %NtKeyboardInput
 */
#define NT_TYPE_KEYBOARD_INPUT nt_keyboard_input_get_type()
NT_DECLARE_TYPE(NT, KEYBOARD_INPUT, NtKeyboardInput, nt_keyboard_input);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
