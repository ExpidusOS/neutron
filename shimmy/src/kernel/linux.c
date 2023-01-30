#include <neutron/shimmy.h>
#define __USE_GNU
#include <sys/ucontext.h>
#include <assert.h>
#include <stdio.h>
#include <signal.h>
#include <setjmp.h>
#include <string.h>
#include <ucontext.h>
#include <unistd.h>

struct Context {
  NtShim id;
  struct sigaction old_sa;
  ucontext_t uctx;
  sigjmp_buf env;
  size_t data_size;
  char stack[];
};

#if defined(AARCH64)
#define CPU_ENTRY REG_X0
#elif defined(ARM)
#define CPU_ENTRY REG_R0
#elif defined(RISCV32)
#define CPU_ENTRY REG_A0
#elif defined(RISCV64)
#define CPU_ENTRY REG_A0
#elif defined(X86_64)
#define CPU_ENTRY REG_RAX
#elif defined(X86)
#define CPU_ENTRY REG_EAX
#else
#error "CPU not supported"
#endif

static void nt_shimmy_linux_handler(int sig, siginfo_t* info, void* uctx_ptr) {
  if (sig != SIGSEGV) return;

  struct Context* ctx = info->si_value.sival_ptr;
  if (ctx == NULL) return;

  NtShimBinding* binding = nt_shimmy_get_shim(ctx->id);
  if (binding != NULL) {
    void* value = binding->handler(binding, ctx->stack, ctx->data_size);
    ctx->uctx.uc_mcontext.gregs[CPU_ENTRY] = (uintptr_t)value;

    sigaction(SIGSEGV, &ctx->old_sa, NULL);
    siglongjmp(ctx->env, 1);
  }
}

void* nt_shimmy_exec(const char* lib, const char* method, void* data, size_t data_size) {
  NtShim id = nt_shimmy_find(lib, method);
  assert(id != NT_SHIM_NONE);

  struct Context* ctx = alloca(sizeof (struct Context) + data_size);
  ctx->id = id;
  ctx->data_size = data_size;

  struct sigaction act = {};
  act.sa_sigaction = nt_shimmy_linux_handler;
  act.sa_flags = SA_SIGINFO;
  assert(sigaction(SIGSEGV, &act, &ctx->old_sa) == 0);

  memcpy(ctx->stack, data, data_size);

  union sigval value = {
    .sival_ptr = ctx
  };

  if (sigsetjmp(ctx->env, 1) == 0) {
    sigqueue(getpid(), SIGSEGV, value);
    sigaction(SIGSEGV, &ctx->old_sa, NULL);
    return NULL;
  }
  return (void*)ctx->uctx.uc_mcontext.gregs[CPU_ENTRY];
}
