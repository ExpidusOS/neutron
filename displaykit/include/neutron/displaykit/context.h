#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: context
 * @title: Context
 * @short_description: An abstract type for all clients and compositors
 */

/**
 * NtDisplayContext:
 * @instance: The %NtTypeInstance associated with this
 * @view_new: Event emitted when a new view is created
 * @output_new: Event emitted when a new output is created
 *
 * An abstract type for all clients and compositors 
 */
typedef struct _NtDisplayContext {
  NtTypeInstance instance;
  NtSignal* view_new;
  NtSignal* output_new;
} NtDisplayContext;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_CONTEXT:
 *
 * The %NtType for %NtDisplayContext
 */
#define NT_TYPE_DISPLAY_CONTEXT nt_display_context_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_CONTEXT, NtDisplayContext, nt_display_context);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
