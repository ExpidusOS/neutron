#include <neutron/shimmy.h>

void nt_shimmy_init() {}

void* nt_shimmy_exec(const char* lib, const char* method, void* data, size_t data_size) {
  NtShim id = nt_shimmy_find(lib, method);
  assert(id != NT_SHIM_NONE);

  NtShimBinding* binding = nt_shimmy_get_shim(id);
  assert(binding != NULL);
  return binding->handler(binding, data, data_size);
}
