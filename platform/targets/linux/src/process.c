#include <neutron/platform/linux-platform.h>
#include <neutron/platform/linux-process.h>
#include <assert.h>
#include <stdlib.h>
#include "process-priv.h"

NT_DEFINE_TYPE(NT, LINUX_PROCESS, NtLinuxProcess, nt_linux_process, NT_TYPE_FLAG_STATIC, NT_TYPE_PROCESS, NT_TYPE_NONE);

static void nt_linux_process_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtLinuxProcess* self = NT_LINUX_PROCESS(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtLinuxProcessPrivate));
  assert(self->priv != NULL);

  NtValue value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtLinuxProcess, pid), NT_VALUE_NUMBER(0));
  assert(value.type == NT_VALUE_TYPE_NUMBER);
  self->priv->pid = value.data.number;
}

static void nt_linux_process_destroy(NtTypeInstance* instance) {
  NtLinuxProcess* self = NT_LINUX_PROCESS(instance);
  assert(self != NULL);

  free(self->priv);
}

NtProcess* nt_linux_process_new(NtPlatform* platform, pid_t pid) {
  assert(NT_IS_LINUX_PLATFORM((NtLinuxPlatform*)platform));

  return NT_PROCESS(nt_type_instance_new(NT_TYPE_LINUX_PROCESS, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtProcess, platform), NT_VALUE_INSTANCE((NtTypeInstance*)platform) },
    { NT_TYPE_ARGUMENT_KEY(NtLinuxProcess, pid), NT_VALUE_NUMBER(pid) },
    { NULL },
  }));
}
