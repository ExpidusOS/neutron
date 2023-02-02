#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: output
 * @title: Output
 * @short_description: A display output
 */

/**
 * NtDisplayOutput:
 * @instance: The %NtTypeInstance associated with this
 *
 * A display output
 */
typedef struct _NtDisplayOutput {
  NtTypeInstance instance;
} NtDisplayOutput;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_OUTPUT:
 *
 * The %NtType for %NtDisplayOutput
 */
#define NT_TYPE_DISPLAY_OUTPUT nt_display_output_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_OUTPUT, NtDisplayOutput, nt_display_output);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
