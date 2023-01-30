#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: scene-layer
 * @title: Scene Layer
 * @short_description: A layer in a scene for rendering
 */

struct _NtRenderer;

/**
 * NtSceneLayer:
 * @instance: The %NtTypeInstance associated with this
 * @render: Method for rendering
 * @clean: Method for cleaning
 * @priv: Private data
 *
 * A layer in a scene for rendering
 */
typedef struct _NtSceneLayer {
  NtTypeInstance instance;

  void (*render)(struct _NtSceneLayer* self, struct _NtRenderer* renderer);
  void (*clean)(struct _NtSceneLayer* self);

  /*< private >*/
  struct _NtSceneLayerPrivate* priv;
} NtSceneLayer;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_SCENE_LAYER:
 *
 * The %NtType for %NtSceneLayer
 */
#define NT_TYPE_SCENE_LAYER nt_scene_layer_get_type()
NT_DECLARE_TYPE(NT, SCENE_LAYER, NtSceneLayer, nt_scene_layer);

/**
 * nt_scene_layer_render:
 * @self: The scene layer
 * @renderer: The renderer
 *
 * Renders the scene layer (@self) onto the renderer (@renderer)
 */
void nt_scene_layer_render(NtSceneLayer* self, struct _NtRenderer* renderer);

/**
 * nt_scene_layer_clean:
 * @self: The scene layer
 *
 * Cleans the scene layers
 */
void nt_scene_layer_clean(NtSceneLayer* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
