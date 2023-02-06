#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: view
 * @title: View
 * @short_description: An object for rendering onto, essentially a window
 */

/**
 * NtDisplayView:
 * @instance: The %NtTypeInstance associated with this
 * @destroy: The event emitted when the view is destroyed
 *
 * A window
 */
typedef struct _NtDisplayView {
  NtTypeInstance instance;
  NtSignal* destroy;
} NtDisplayView;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_VIEW:
 *
 * The %NtType for %NtDisplayView
 */
#define NT_TYPE_DISPLAY_VIEW nt_display_view_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_VIEW, NtDisplayView, nt_display_view);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
