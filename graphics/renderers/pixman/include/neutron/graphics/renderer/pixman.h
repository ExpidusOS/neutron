#pragma once

#include <neutron/graphics/renderer.h>
#include <neutron/graphics/build.h>

#ifdef NT_GRAPHICS_HAS_PIXMAN

/**
 * SECTION: pixman
 * @title: Pixman Renderer
 * @short_description: A software renderer using Pixman
 * @see_also: #NtRenderer
 * @include: neutron/graphics/renderer/pixman.h
 */

/**
 * NtPixmanRenderer:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * A software renderer using Pixman
 */
typedef struct _NtPixmanRenderer {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtPixmanRendererPrivate* priv;
} NtPixmanRenderer;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_PIXMAN_RENDERER:
 *
 * The %NtType for %NtPixmanRenderer
 */
#define NT_TYPE_PIXMAN_RENDERER nt_pixman_renderer_get_type()
NT_DECLARE_TYPE(NT, PIXMAN_RENDERER, NtPixmanRenderer, nt_pixman_renderer);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS

#endif
