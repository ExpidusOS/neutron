#include <neutron/platform/platform.h>
#include <assert.h>
#include "platform-priv.h"

static NtPlatform* global;

static void nt_platform_construct(NtTypeInstance* inst, void* data) {
  assert(global == NULL);
}

static void nt_platform_destroy(NtTypeInstance* inst, void* data) {
  global = NULL;
}

NT_EXPORT NtType nt_platform_get_type() {
  static NtType id = NT_TYPE_NONE;

  if (id == NT_TYPE_NONE) {
    static NtTypeInfo info = {};
    info.flags = NT_TYPE_FLAG_STATIC;
    info.size = NT_PLATFORM_SIZE;
    info.construct = nt_platform_construct;
    info.destroy = nt_platform_destroy;
    id = nt_type_register(&info);
  }
  return id;
}

NT_EXPORT NtPlatform* nt_platform_get_global() {
  if (global == NULL) {
    global = NT_PLATFORM(nt_type_instance_new(NT_TYPE_PLATFORM));
  }
  return NT_PLATFORM(nt_type_instance_ref((NtTypeInstance*)global));
}
