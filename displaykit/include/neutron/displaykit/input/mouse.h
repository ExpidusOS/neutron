#pragma once

#include <neutron/elemental.h>
#include <neutron/displaykit/input.h>

/**
 * SECTION: mouse
 * @title: Mouse Input
 * @short_description: A mouse input device
 */

/**
 * NtDisplayMouseInput:
 * @instance: The %NtTypeInstance associated with this
 * @see_also: %NtDisplayInput
 *
 * Mouse input on a display server
 */
typedef struct _NtDisplayMouseInput {
  NtTypeInstance instance;
} NtDisplayMouseInput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_MOUSE_INPUT:
 *
 * The %NtType for %NtDisplayMouseInput
 */
#define NT_TYPE_DISPLAY_MOUSE_INPUT nt_display_mouse_input_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_MOUSE_INPUT, NtDisplayMouseInput, nt_display_mouse_input);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
