#pragma once

#include <neutron/graphics/renderer.h>
#include <neutron/graphics/build.h>
#include <EGL/egl.h>

#ifdef NT_GRAPHICS_HAS_EGL

/**
 * SECTION: egl
 * @title: EGL Renderer
 * @short_description: A hardware renderer using EGL
 * @see_also: #NtRenderer
 */

/**
 * NtEGLRenderer:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * A hardware renderer using EGL
 */
typedef struct _NtEGLRenderer {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtEGLRendererPrivate* priv;
} NtEGLRenderer;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_EGL_RENDERER:
 *
 * The %NtType for %NtEGLRenderer
 */
#define NT_TYPE_EGL_RENDERER nt_egl_renderer_get_type()
NT_DECLARE_TYPE(NT, EGL_RENDERER, NtEGLRenderer, nt_egl_renderer);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS

#endif
