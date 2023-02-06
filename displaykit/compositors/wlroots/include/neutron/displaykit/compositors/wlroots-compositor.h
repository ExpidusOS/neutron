#pragma once

#include <neutron/displaykit/compositor.h>
#include <stdbool.h>

/**
 * SECTION: wlroots-compositor
 * @title: Wlroots Compositor
 * @short_description: A compositor for Wayland using the wlroots library
 * @see_also: #NtDisplayCompositor
 */

/**
 * NtWlrootsCompositor:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * A compositor for Wayland using wlroots
 */
typedef struct _NtWlrootsCompositor {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtWlrootsCompositorPrivate* priv;
} NtWlrootsCompositor;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_WLROOTS_COMPOSITOR:
 *
 * The %NtType for %NtWlrootsCompositor
 */
#define NT_TYPE_WLROOTS_COMPOSITOR nt_wlroots_compositor_get_type()
NT_DECLARE_TYPE(NT, WLROOTS_COMPOSITOR, NtWlrootsCompositor, nt_wlroots_compositor);

/**
 * nt_wlroots_compositor_new:
 * @backtrace: The backtrace to use if an error occurs
 * @error: Pointer to store the error
 *
 * Creates a new Wayland compositor using wlroots
 *
 * Returns: A new compositor instance
 */
NtDisplayCompositor* nt_wlroots_compositor_new(NtBacktrace* backtrace, NtError** error);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
