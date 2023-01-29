#pragma once

#include <neutron/elemental.h>

NT_BEGIN_DECLS

/**
 * SECTION: context
 * @title: Context
 * @short_description: Context for the runtime
 */

/**
 * NtRuntimeContext:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * Context for the runtime
 */
typedef struct _NtRuntimeContext {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtRuntimeContextPrivate* priv;
} NtRuntimeContext;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_RUNTIME_CONTEXT:
 *
 * The %NtType for %NtRuntimeContext
 */
#define NT_TYPE_RUNTIME_CONTEXT nt_runtime_context_get_type()
NT_DECLARE_TYPE(NT, RUNTIME_CONTEXT, NtRuntimeContext, nt_runtime_context);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
