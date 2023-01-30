#include <neutron/graphics/renderer.h>
#include <neutron/graphics/scene-layer.h>
#include <assert.h>
#include "scene-layer-priv.h"

NT_DEFINE_TYPE(NT, SCENE_LAYER, NtSceneLayer, nt_scene_layer, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_scene_layer_construct(NtTypeInstance* inst, NtTypeArgument* arguments) {
  NtSceneLayer* self = NT_SCENE_LAYER(inst);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtSceneLayerPrivate));
  assert(self->priv != NULL);

  NtValue layer = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtSceneLayer, flutter-layer), NT_VALUE_POINTER(NULL));
  assert(layer.type == NT_VALUE_TYPE_POINTER);
  self->priv->layer = layer.data.pointer;
}

static void nt_scene_layer_destroy(NtTypeInstance* inst) {
  NtSceneLayer* self = NT_SCENE_LAYER(inst);
  assert(self != NULL);
  free(self->priv);
}

void nt_scene_layer_render(NtSceneLayer* self, struct _NtRenderer* renderer) {
  assert(NT_IS_SCENE_LAYER(self));
  assert(NT_IS_RENDERER(renderer));
  assert(self->render != NULL);
  self->render(self, renderer);
}

void nt_scene_layer_clean(NtSceneLayer* self) {
  assert(NT_IS_SCENE_LAYER(self));
  assert(self->clean != NULL);
  self->clean(self);
}
