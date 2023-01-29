#include <neutron/graphics/renderer/pixman.h>
#include <assert.h>
#include <stdlib.h>
#include "pixman-renderer-priv.h"

NT_DEFINE_TYPE(NT, PIXMAN_RENDERER, NtPixmanRenderer, nt_pixman_renderer, NT_TYPE_FLAG_STATIC, NT_TYPE_RENDERER);

static bool nt_pixman_renderer_surface_present_callback(void* user_data, const void* alloc, size_t rows, size_t height) {
  NtPixmanRenderer* self = NT_PIXMAN_RENDERER(user_data);
  assert(self != NULL);

  if (self->priv->image != NULL) {
    pixman_image_t* tmp = pixman_image_create_bits(PIXMAN_r8g8b8x8, rows, height, (uint32_t*)alloc, rows * 4);
    pixman_image_composite(PIXMAN_OP_SRC, tmp, NULL, self->priv->image, 0, 0, 0, 0, 0, 0, rows, height);
    pixman_image_unref(tmp);
  }
  return true;
}

static bool nt_pixman_renderer_is_software(NtRenderer* renderer) {
  return true;
}

static FlutterRendererConfig* nt_pixman_renderer_get_config(NtRenderer* renderer) {
  NtPixmanRenderer* self = NT_PIXMAN_RENDERER((NtTypeInstance*)renderer);
  assert(self != NULL);
  return &self->priv->config;
}

static void nt_pixman_renderer_construct(NtTypeInstance* inst, NtTypeArgument* arguments) {
  NtRenderer* renderer = NT_RENDERER(inst);
  assert(renderer != NULL);

  renderer->is_software = nt_pixman_renderer_is_software;
  renderer->get_config = nt_pixman_renderer_get_config;

  NtPixmanRenderer* self = NT_PIXMAN_RENDERER(inst);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtPixmanRendererPrivate));
  assert(self->priv != NULL);

  self->priv->image = NULL;

  self->priv->config.type = kSoftware;
  self->priv->config.software.struct_size = sizeof (FlutterSoftwareRendererConfig);
  self->priv->config.software.surface_present_callback = nt_pixman_renderer_surface_present_callback;

  NtValue image = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtPixmanRenderer, image), NT_VALUE_POINTER(NULL));
  assert(image.type == NT_VALUE_TYPE_POINTER);

  if (image.data.pointer != NULL) {
    self->priv->image = pixman_image_ref((pixman_image_t*)image.data.pointer);
    assert(self->priv->image != NULL);
  }
}

static void nt_pixman_renderer_destroy(NtTypeInstance* inst) {
  NtPixmanRenderer* self = NT_PIXMAN_RENDERER(inst);
  assert(self != NULL);

  if (self->priv->image != NULL) {
    pixman_image_unref(self->priv->image);
    self->priv->image = NULL;
  }

  free(self->priv);
}

pixman_image_t* nt_pixman_renderer_get_image(NtPixmanRenderer* self) {
  assert(NT_IS_PIXMAN_RENDERER(self));

  if (self->priv->image == NULL) return NULL;
  return pixman_image_ref(self->priv->image);
}

void nt_pixman_renderer_set_image(NtPixmanRenderer* self, pixman_image_t* image) {
  assert(NT_IS_PIXMAN_RENDERER(self));
  assert(image != NULL);

  if (self->priv->image != NULL) {
    pixman_image_unref(self->priv->image);
    self->priv->image = NULL;
  }

  self->priv->image = pixman_image_ref(image);
  assert(self->priv->image != NULL);
}
