#pragma once

#include <neutron/graphics/renderer/pixman.h>
#include <pixman.h>

typedef struct _NtPixmanRendererPrivate {
  FlutterRendererConfig config;

  pixman_image_t* image;
} NtPixmanRendererPrivate;
