#pragma once

#include <neutron/elemental/pthread.h>
#include <neutron/graphics/renderer.h>

typedef struct _NtRendererPrivate {
  pthread_mutex_t mutex;
} NtRendererPrivate;
