#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: input
 * @title: Input
 * @short_description: An input device
 */

/**
 * NtDisplayInput:
 * @instance: The %NtTypeInstance associated with this
 *
 * An input device on a display server
 */
typedef struct _NtDisplayInput {
  NtTypeInstance instance;
} NtDisplayInput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_INPUT:
 *
 * The %NtType for %NtDisplayInput
 */
#define NT_TYPE_DISPLAY_INPUT nt_display_input_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_INPUT, NtDisplayInput, nt_display_input);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
