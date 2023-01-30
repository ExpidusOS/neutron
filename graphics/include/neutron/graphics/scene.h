#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: scene
 * @title: Scene
 * @short_description: Scenes for rendering
 */

struct _NtRenderer;
struct _NtSceneLayer;

/**
 * NtScene:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * Scene for rendering layers
 */
typedef struct _NtScene {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtScenePrivate* priv;
} NtScene;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_SCENE:
 *
 * The %NtType for %NtScene
 */
#define NT_TYPE_SCENE nt_scene_get_type()
NT_DECLARE_TYPE(NT, SCENE, NtScene, nt_scene);

/**
 * nt_scene_new:
 *
 * Creates a new scene.
 * Returns: A new scene.
 */
NtScene* nt_scene_new();

/**
 * nt_scene_add_layer:
 * @self: The scene
 * @renderer: The layer
 *
 * Adds the layer into the scene. This does not reference the layer.
 */
void nt_scene_add_layer(NtScene* self, struct _NtSceneLayer* layer);

/**
 * nt_scene_render:
 * @self: The scene
 * @renderer: The renderer
 *
 * Renders the scene (@self) onto the renderer (@renderer).
 */
void nt_scene_render(NtScene* self, struct _NtRenderer* renderer);

/**
 * nt_scene_clean:
 * @self: The scene
 *
 * Cleans the scene's layers
 */
void nt_scene_clean(NtScene* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
