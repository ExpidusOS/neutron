#pragma once

#include <neutron/graphics/renderer.h>
#include <neutron/graphics/build.h>
#include <pixman.h>

#ifdef NT_GRAPHICS_HAS_PIXMAN

/**
 * SECTION: pixman
 * @title: Pixman Renderer
 * @short_description: A software renderer using Pixman
 * @see_also: #NtRenderer
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

/**
 * nt_pixman_renderer_new:
 * @image: The Pixman Image
 *
 * Creates a new %NtPixmanRenderer with @image being the Pixman Image that the renderer will output to.
 */
NtRenderer* nt_pixman_renderer_new(pixman_image_t* image);

/**
 * nt_pixman_renderer_get_image:
 * @self: The %NtPixmanRenderer instance
 *
 * Gets the renderer's Pixman image. This calls pixman_image_ref so make sure to call
 * pixman_image_unref when your done with it.
 *
 * Returns: The Pixman Image which is being used
 */
pixman_image_t* nt_pixman_renderer_get_image(NtPixmanRenderer* self);

/**
 * nt_pixman_renderer_set_image:
 * @self: The %NtPixmanRenderer instance
 * @image: The Pixman Image
 *
 * Sets the renderer's Pixman image. This calls pixman_image_ref as the image is set.
 */
void nt_pixman_renderer_set_image(NtPixmanRenderer* self, pixman_image_t* image);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS

#endif
