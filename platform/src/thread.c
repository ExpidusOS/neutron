#include <neutron/platform/thread.h>
#include <assert.h>
#include <stdlib.h>
#include "thread-priv.h"

NT_DEFINE_TYPE(NT, THREAD, NtThread, nt_thread, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_thread_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtThread* self = NT_THREAD(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtThreadPrivate));
  assert(self->priv != NULL);

  self->priv->signal = nt_signal_new_locking();
  self->priv->main.method = NULL;
  self->priv->main.data = NULL;
}

static void nt_thread_destroy(NtTypeInstance* instance) {
  NtThread* self = NT_THREAD(instance);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->priv->signal);
  free(self->priv);
}

static bool nt_thread_signal_exec(NtSignal* signal, NtTypeArgument* arguments, const void* data) {
  NtThreadClosure* closure = (NtThreadClosure*)data;

  NtValue instance = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtThread, instance), NT_VALUE_INSTANCE(NULL));
  assert(instance.type == NT_VALUE_TYPE_INSTANCE);
  assert(instance.data.instance != NULL);

  NtValue result_value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtThread, result), NT_VALUE_POINTER(NULL));
  assert(result_value.type == NT_VALUE_TYPE_POINTER);
  assert(result_value.data.pointer != NULL);

  NtThread* thread = NT_THREAD(instance.data.instance);
  assert(thread != NULL);

  void** result = (void**)result_value.data.pointer;
  *result = closure->method(thread, closure->data);
  return true;
}

void* nt_thread_exec(NtThread* self) {
  assert(NT_IS_THREAD(self));

  void* result = NULL;

  nt_signal_emit(self->priv->signal, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtThread, instance), NT_VALUE_INSTANCE((NtTypeInstance*)self) },
    { NT_TYPE_ARGUMENT_KEY(NtThread, result), NT_VALUE_POINTER(&result) },
    { NULL }
  });

  if (self->priv->method == NULL) {
    result = self->priv->method(self, self->priv->method_data);
  }
  return result;
}

int nt_thread_attach_method(NtThread* self, NtThreadMethod method, const void* data) {
  assert(NT_IS_THREAD(self));
  assert(method != NULL);

  NtThreadClosure* closure = malloc(sizeof(NtThreadClosure));
  closure->data = data;
  closure->method = method;
  return nt_signal_attach(self->priv->signal, nt_thread_signal_exec, closure);
}

void* nt_thread_detach_method(NtThread* self, int id) {
  assert(NT_IS_THREAD(self));

  NtThreadClosure* closure = nt_signal_detach(self->priv->signal, id);
  if (closure == NULL) return NULL;

  void* data = (void*)closure->data;
  free(closure);
  return data;
}

NtThreadClosure nt_thread_set_main(NtThread* self, NtThreadMethod method, const void* data) {
  assert(NT_IS_THREAD(self));

  NtThreadClosure old = {};
  old.method = self->priv->closure.method;
  old.data = self->priv->closure.data;

  self->priv->main.method = method;
  self->priv->main.data = data;
  return old;
}
