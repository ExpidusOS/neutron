#include <neutron/runtime/context.h>
#include "context-priv.h"

NT_DEFINE_TYPE(NT, RUNTIME_CONTEXT, NtRuntimeContext, nt_runtime_context, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_runtime_context_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtRuntimeContext* self = NT_RUNTIME_CONTEXT(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtRuntimeContextPrivate));
  assert(self->priv != NULL);
}

static void nt_runtime_context_destroy(NtTypeInstance* instance) {
  NtRuntimeContext* self = NT_RUNTIME_CONTEXT(instance);
  assert(self != NULL);
  free(self->priv);
}

NtRenderer* nt_runtime_context_get_renderer(NtRuntimeContext* self) {
  assert(NT_IS_RUNTIME_CONTEXT(self));
  return self->priv->renderer;
}
