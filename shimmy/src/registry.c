#include <neutron/shimmy.h>
#include <assert.h>
#include <string.h>

struct ShimEntry {
  struct ShimEntry* prev;
  NtShimBinding binding;
  struct ShimEntry* next;
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
