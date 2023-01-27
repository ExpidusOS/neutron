#include <neutron/platform/platform.h>
#include <assert.h>
#include "platform-priv.h"

static NtPlatform* global;

NT_DEFINE_TYPE(NT, PLATFORM, NtPlatform, nt_platform, NT_TYPE_FLAG_STATIC);

static void nt_platform_construct(NtTypeInstance* inst, void* data) {
  assert(global == NULL);
}

static void nt_platform_destroy(NtTypeInstance* inst, void* data) {
  global = NULL;
}

NT_EXPORT NtPlatform* nt_platform_get_global() {
  if (global == NULL) {
    global = NT_PLATFORM(nt_type_instance_new(NT_TYPE_PLATFORM));
  }
  return NT_PLATFORM(nt_type_instance_ref((NtTypeInstance*)global));
}
