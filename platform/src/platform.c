#include <neutron/platform/platform.h>
#include <assert.h>
#include <stdlib.h>
#include "platform-priv.h"

NT_DEFINE_TYPE(NT, PLATFORM, NtPlatform, nt_platform, NT_TYPE_FLAG_STATIC);

static void nt_platform_construct(NtTypeInstance* inst) {
  NtPlatform* self = NT_PLATFORM(inst);

  self->priv = malloc(sizeof (NtPlatformPrivate));
  assert(self->priv != NULL);
}

static void nt_platform_destroy(NtTypeInstance* inst) {
  NtPlatform* self = NT_PLATFORM(inst);

  free(self->priv);
  self->priv = NULL;
}

NtPlatform* nt_platform_get_global() {
  static NtPlatform* global;
  if (global == NULL) {
    global = NT_PLATFORM(nt_type_instance_new(NT_TYPE_PLATFORM));
    assert(global != NULL);
  }
  return NT_PLATFORM(nt_type_instance_ref((NtTypeInstance*)global));
}
