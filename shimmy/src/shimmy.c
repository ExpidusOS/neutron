#include <neutron/elemental/pthread.h>
#include <neutron/shimmy.h>
#include <assert.h>
#include <string.h>

struct ShimEntry {
  struct ShimEntry* prev;
  NtShimBinding binding;
  struct ShimEntry* next;
};

struct ShimCall {
  NtShim shim;
  void* data;
};

static struct ShimEntry* nt_shim_registry = NULL;

NtShim nt_shimmy_bind(const char* lib, const char* method, NtShimMethod handler) {
  struct ShimEntry* entry = malloc(sizeof (struct ShimEntry));
  assert(entry != NULL);
  assert(handler != NULL);

  entry->binding.lib = lib;
  entry->binding.method = method;
  entry->binding.handler = handler;
  entry->binding.id = (NtShim)&entry->binding;
  entry->prev = nt_shim_registry;
  entry->next = NULL;

  if (nt_shim_registry != NULL) {
    nt_shim_registry->prev = entry;
  }

  nt_shim_registry = entry;
  return entry->binding.id;
}

NtShimBinding* nt_shimmy_get_shim(NtShim id) {
  for (struct ShimEntry* entry = nt_shimmy_get_reg(); entry != NULL; entry = entry->next) {
    if (entry->binding.id == id) {
      return &entry->binding;
    }
  }
  return NULL;
}

NtShim nt_shimmy_find(const char* lib, const char* method) {
  for (struct ShimEntry* entry = nt_shimmy_get_reg(); entry != NULL; entry = entry->next) {
    if (strcmp(entry->binding.lib, lib) == 0 && strcmp(entry->binding.method, method) == 0) {
      return entry->binding.id;
    }
  }
  return NT_SHIM_NONE;
}

void nt_shimmy_unbind(NtShim id) {
  for (struct ShimEntry* entry = nt_shim_registry; entry != NULL; entry = entry->next) {
    if (entry->binding.id == id) {
      if (entry == nt_shim_registry) {
        nt_shim_registry = NULL;
      }

      if (entry->prev != NULL) entry->prev->next = entry->next;
      if (entry->next != NULL) entry->next->prev = entry->prev;
      free(entry);
      break;
    }
  }
}

void* nt_shimmy_get_reg() {
  return nt_shim_registry;
}

static NtProcessSignalResult nt_shimmy_signal_handler(NtProcess* proc, NtProcessSignal* signal, const void* data) {
  if (signal->is_exception) {
    if (signal->exception.kind == NT_PROCESS_EXCEPTION_SEG_VIO) {
      struct ShimCall* call = (struct ShimCall*)data;

      NtShimBinding* binding = nt_shimmy_get_shim(call->shim);
      if (binding != NULL) {
        void* value = binding->handler(binding, call->data);

        signal->is_return = true;
        signal->is_exception = false;

        signal->return_data.arg0 = value;
        signal->return_data.arg1 = NULL;
        signal->return_data.arg2 = NULL;
        signal->return_data.arg3 = NULL;
        return NT_SIGNAL_STOP | NT_SIGNAL_RETURN;
      }
    }
  }
  return NT_SIGNAL_CONTINUE;
}

void* nt_shimmy_exec(NtProcess* proc, const char* lib, const char* method, void* data) {
  static pthread_mutex_t mutex;

  NtShim shim = nt_shimmy_find(lib, method);
  assert(shim != NT_SHIM_NONE);

  struct ShimCall* call = alloca(sizeof (struct ShimCall));
  assert(call != NULL);

  call->shim = shim;
  call->data = data;

  pthread_mutex_lock(&mutex);
  int id = nt_process_attach_signal(proc, nt_shimmy_signal_handler, call);

  void* ret = nt_process_send_signal(proc, NT_PROCESS_EXCEPTION_SEG_VIO, NT_PROCESS_INTERRUPT_NONE);

  nt_process_detach_signal(proc, id);
  pthread_mutex_unlock(&mutex);
  return ret;
}
