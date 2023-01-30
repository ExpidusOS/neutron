#include <neutron/graphics/renderer.h>
#include <neutron/graphics/scene.h>
#include <assert.h>
#include <stdlib.h>
#include "scene-priv.h"

NT_DEFINE_TYPE(NT, SCENE, NtScene, nt_scene, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_scene_construct(NtTypeInstance* inst, NtTypeArgument* arguments) {
  NtScene* self = NT_SCENE(inst);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtScenePrivate));
  assert(self->priv != NULL);
  self->priv->layers = NULL;

  assert(pthread_mutex_init(&self->priv->mutex, NULL) == 0);
}

static void nt_scene_destroy(NtTypeInstance* inst) {
  NtScene* self = NT_SCENE(inst);
  assert(self != NULL);

  for (struct SceneLayerEntry* entry = self->priv->layers; entry != NULL;) {
    struct SceneLayerEntry* next = entry->next;

    nt_type_instance_unref((NtTypeInstance*)entry->layer);
    free(entry);

    entry = next;
  }

  pthread_mutex_destroy(&self->priv->mutex);
  free(self->priv);
}

void nt_scene_add_layer(NtScene* self, struct _NtSceneLayer* layer) {
  assert(NT_IS_SCENE(self));
  assert(NT_IS_SCENE_LAYER(layer));

  pthread_mutex_lock(&self->priv->mutex);

  struct SceneLayerEntry* entry = malloc(sizeof (struct SceneLayerEntry));
  entry->layer = layer;
  entry->prev = NULL;
  entry->next = self->priv->layers;

  if (self->priv->layers != NULL) {
    self->priv->layers->prev = entry;
  }

  self->priv->layers = entry;

  pthread_mutex_unlock(&self->priv->mutex);
}

void nt_scene_render(NtScene* self, struct _NtRenderer* renderer) {
  assert(NT_IS_SCENE(self));
  assert(NT_IS_RENDERER(renderer));

  pthread_mutex_lock(&self->priv->mutex);

  for (struct SceneLayerEntry* entry = self->priv->layers; entry != NULL; entry = entry->next) {
    assert(entry->layer != NULL);
    nt_scene_layer_render(entry->layer, renderer);
  }

  pthread_mutex_unlock(&self->priv->mutex);
}

void nt_scene_clean(NtScene* self) {
  assert(NT_IS_SCENE(self));

  pthread_mutex_lock(&self->priv->mutex);

  for (struct SceneLayerEntry* entry = self->priv->layers; entry != NULL; entry = entry->next) {
    assert(entry->layer != NULL);
    nt_scene_layer_clean(entry->layer);
  }

  pthread_mutex_unlock(&self->priv->mutex);
}
