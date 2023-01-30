#pragma once

#include <neutron/graphics/scene.h>
#include <neutron/graphics/scene-layer.h>
#include <pthread.h>

struct SceneLayerEntry {
  struct SceneLayerEntry* prev;
  NtSceneLayer* layer;
  struct SceneLayerEntry* next;
};

typedef struct _NtScenePrivate {
  struct SceneLayerEntry* layers;
  pthread_mutex_t mutex;
} NtScenePrivate;
