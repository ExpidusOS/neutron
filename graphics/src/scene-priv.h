#pragma once

#include <neutron/elemental/pthread.h>
#include <neutron/graphics/scene.h>
#include <neutron/graphics/scene-layer.h>

struct SceneLayerEntry {
  struct SceneLayerEntry* prev;
  NtSceneLayer* layer;
  struct SceneLayerEntry* next;
};

typedef struct _NtScenePrivate {
  struct SceneLayerEntry* layers;
  pthread_mutex_t mutex;
} NtScenePrivate;
