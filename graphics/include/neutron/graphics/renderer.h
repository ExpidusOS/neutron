#pragma once

#include <neutron/elemental.h>
#include <flutter_embedder.h>
#include <stdbool.h>

/**
 * SECTION: renderer
 * @title: Renderer
 * @short_description: Generic renderer API
 */

/**
 * NtRenderer:
 * @instance: The %NtTypeInstance associated with this
 * @is_software: Method for getting whether or not the renderer is doing software rendering
 * @get_config: Method for getting the renderer configuration for Flutter
 * @get_compositor: Method for getting the compositor for Flutter
 * @wait_sync: Method for causing the renderer to wait for synchronization
 * @render: Method for causing the renderer to perform the rendering action
 * @pre_render: Signal triggered before rendering begins
 * @post_render: Signal triggered once rendering is done
 *
 * Base type for a renderer
 */
typedef struct _NtRenderer {
  NtTypeInstance instance;

  bool (*is_software)(struct _NtRenderer* self);
  FlutterRendererConfig* (*get_config)(struct _NtRenderer* self);
  FlutterCompositor* (*get_compositor)(struct _NtRenderer* self);
  void (*wait_sync)(struct _NtRenderer* self);
  void (*render)(struct _NtRenderer* self);

  NtSignal* pre_render;
  NtSignal* post_render;

  /*< private >*/
  struct _NtRendererPrivate* priv;
} NtRenderer;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_RENDERER:
 *
 * The %NtType for %NtRenderer
 */
#define NT_TYPE_RENDERER nt_renderer_get_type()
NT_DECLARE_TYPE(NT, RENDERER, NtRenderer, nt_renderer);

/**
 * nt_renderer_is_software:
 * @self: The %NtRenderer instance
 *
 * Gets whether or not the renderer is using software or hardware rendering.
 * Returns: %true if the renderer is software rendering, %false if the renderer is hardware rendering
 */
bool nt_renderer_is_software(NtRenderer* self);

/**
 * nt_renderer_get_config:
 * @self: The %NtRenderer instance
 *
 * Gets the renderer configuration for Flutter
 * Returns: A pointer to the renderer configuration
 */
FlutterRendererConfig* nt_renderer_get_config(NtRenderer* self);

/**
 * nt_renderer_get_compositor:
 * @self: The %NtRenderer instance
 *
 * Gets the compositor for Flutter
 * Returns: A pointer to the compositor
 */
FlutterCompositor* nt_renderer_get_compositor(NtRenderer* self);

/**
 * nt_renderer_wait_sync:
 * @self: The %NtRenderer instance
 *
 * Causes the renderer to wait for any synchronization action.
 * Use this before calling %nt_renderer_render.
 */
void nt_renderer_wait_sync(NtRenderer* self);

/**
 * nt_renderer_render:
 * @self: The %NtRenderer instance
 *
 * Causes the renderer to actually render.
 * This does not use %nt_renderer_wait_sync so be sure to call it first.
 */
void nt_renderer_render(NtRenderer* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
