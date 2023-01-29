#pragma once

#include <neutron/graphics/renderer.h>
#include <pthread.h>

typedef struct _NtRendererPrivate {
  pthread_mutex_t mutex;
} NtRendererPrivate;
