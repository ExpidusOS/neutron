#include <neutron/platform/device.h>
#include <assert.h>
#include <stdlib.h>
#include "process-priv.h"

NT_DEFINE_TYPE(NT, PROCESS, NtProcess, nt_process, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static bool nt_process_signal_handler(NtSignal* signal, NtTypeArgument* arguments, const void* data) {
  NtProcessSignalEntry* sig = (NtProcessSignalEntry*)data;

  NtValue sigdata = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtProcessSignal, signal), NT_VALUE_POINTER(NULL));
  assert(sigdata.type == NT_VALUE_TYPE_POINTER);
  assert(sigdata.data.pointer != NULL);

  NtValue resultptr = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtProcessSignal, result), NT_VALUE_POINTER(NULL));
  assert(resultptr.type == NT_VALUE_TYPE_POINTER);
  assert(resultptr.data.pointer != NULL);

  NtProcessSignalResult* result = (NtProcessSignalResult*)resultptr.data.pointer;

  sig->result = sig->handler(sig->proc, sigdata.data.pointer, sig->data);

  if (sig->result & NT_SIGNAL_RETURN) *result |= NT_SIGNAL_RETURN;
  else if (sig->result & NT_SIGNAL_QUIT) *result |= NT_SIGNAL_QUIT;

  if (sig->result & NT_SIGNAL_CONTINUE) return true;
  return false;
}

static void nt_process_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtProcess* self = NT_PROCESS(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtProcessPrivate));
  assert(self->priv != NULL);

  self->priv->signal = nt_signal_new_locking();
}

static void nt_process_destroy(NtTypeInstance* instance) {
  NtProcess* self = NT_PROCESS(instance);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->priv->signal);
  free(self->priv);
}

int nt_process_attach_signal(NtProcess* self, NtProcessSignalHandler handler, void* data) {
  assert(NT_IS_PROCESS(self));
  assert(handler != NULL);

  NtProcessSignalEntry* sig = malloc(sizeof (NtProcessSignalEntry));
  assert(sig != NULL);
  sig->proc = self;
  sig->handler = handler;
  sig->data = data;
  return nt_signal_attach(self->priv->signal, nt_process_signal_handler, sig);
}

void* nt_process_detach_signal(NtProcess* self, int id) {
  assert(NT_IS_PROCESS(self));

  NtProcessSignalEntry* sig = (NtProcessSignalEntry*)nt_signal_detach(self->priv->signal, id);
  if (sig == NULL) return NULL;

  void* data = (void*)sig->data;
  free(sig);
  return data;
}
