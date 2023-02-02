#pragma once

#include <neutron/elemental.h>
#include <neutron/displaykit/input.h>

/**
 * SECTION: keyboard
 * @title: Keyboard Input
 * @short_description: A keyboard input device
 */

/**
 * NtDisplayKeyboardInput:
 * @instance: The %NtTypeInstance associated with this
 * @see_also: %NtDisplayInput
 *
 * Keyboard input on a display server
 */
typedef struct _NtDisplayKeyboardInput {
  NtTypeInstance instance;
} NtDisplayKeyboardInput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_KEYBOARD_INPUT:
 *
 * The %NtType for %NtDisplayKeyboardInput
 */
#define NT_TYPE_DISPLAY_KEYBOARD_INPUT nt_display_keyboard_input_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_KEYBOARD_INPUT, NtDisplayKeyboardInput, nt_display_keyboard_input);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
