#pragma once

#include <neutron/displaykit/context.h>

/**
 * SECTION: compositor
 * @title: Compositor
 * @short_description: Compositor API
 */

/**
 * NtDisplayCompositor:
 * @instance: The %NtTypeInstance associated with this
 */
typedef struct _NtDisplayCompositor {
  NtTypeInstance instance;
} NtDisplayCompositor;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_COMPOSITOR:
 *
 * The %NtType for %NtDisplayCompositor
 */
#define NT_TYPE_DISPLAY_COMPOSITOR nt_display_compositor_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_COMPOSITOR, NtDisplayCompositor, nt_display_compositor);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
