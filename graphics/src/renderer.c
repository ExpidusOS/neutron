#include <neutron/graphics/renderer.h>
#include <assert.h>
#include <stdlib.h>
#include "renderer-priv.h"

NT_DEFINE_TYPE(NT, RENDERER, NtRenderer, nt_renderer, NT_TYPE_FLAG_DYNAMIC);

static void nt_renderer_construct(NtTypeInstance* inst, NtTypeArgument* arguments) {
  NtRenderer* self = NT_RENDERER(inst);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtRendererPrivate));
  assert(self->priv != NULL);
  assert(pthread_mutex_init(&self->priv->mutex, NULL) == 0);

  self->pre_render = nt_signal_new_locking();
  self->post_render = nt_signal_new_locking();
}

static void nt_renderer_destroy(NtTypeInstance* inst) {
  NtRenderer* self = NT_RENDERER(inst);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->pre_render);
  nt_type_instance_unref((NtTypeInstance*)self->post_render);

  pthread_mutex_destroy(&self->priv->mutex);
  free(self->priv);
}

bool nt_renderer_is_software(NtRenderer* self) {
  assert(NT_IS_RENDERER(self));
  assert(self->is_software != NULL);
  return self->is_software(self);
}

FlutterRendererConfig* nt_renderer_get_config(NtRenderer* self) {
  assert(NT_IS_RENDERER(self));
  assert(self->get_config != NULL);
  return self->get_config(self);
}

FlutterCompositor* nt_renderer_get_compositor(NtRenderer* self) {
  assert(NT_IS_RENDERER(self));
  assert(self->get_compositor != NULL);
  return self->get_compositor(self);
}

void nt_renderer_wait_sync(NtRenderer* self) {
  assert(NT_IS_RENDERER(self));
  assert(self->wait_sync != NULL);
  self->wait_sync(self);
}

void nt_renderer_render(NtRenderer* self) {
  assert(NT_IS_RENDERER(self));
  assert(self->render != NULL);

  pthread_mutex_lock(&self->priv->mutex);

  NtTypeArgument arguments[] = {
    { NT_TYPE_ARGUMENT_KEY(NtRenderer, instance), NT_VALUE_INSTANCE((NtTypeInstance*)self) },
    { NULL }
  };

  nt_signal_emit(self->pre_render, arguments);
  self->render(self);
  nt_signal_emit(self->post_render, arguments);

  pthread_mutex_unlock(&self->priv->mutex);
}
