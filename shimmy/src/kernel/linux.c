#include <neutron/shimmy.h>
#include <assert.h>
#include <signal.h>
#include <ucontext.h>

static void nt_shimmy_linux_handler(int sig, siginfo_t* info, void* uctx_ptr) {
  if (sig != SIGSEGV) return;

  NtShim id = (NtShim)info->si_addr;
  NtShimBinding* binding = nt_shimmy_get_shim(id);
  if (binding != NULL) {
    // TODO: unpack the stack and pass it along
    void* value = binding->handler(binding, NULL, 0);
    (void)value;
    // TODO: take the value and push it to be returned
    // TODO: return from the signal
  }
}

void nt_shimmy_init() {
  struct sigaction act = {};
  act.sa_sigaction = nt_shimmy_linux_handler;
  assert(sigaction(SIGSEGV, &act, NULL) == 0);
}

void* nt_shimmy_exec(const char* lib, const char* method, void* data, size_t data_size) {
  NtShim id = nt_shimmy_find(lib, method);
  if (id == NT_SHIM_NONE) {
    raise(SIGILL);
    return NULL;
  }

  // TODO: set si_addr to use id
  // TODO: use data and data_size to be the stack
  // TODO: raise SIGSEGV
  // TODO: fetch data returned from the signal
  return NULL;
}
