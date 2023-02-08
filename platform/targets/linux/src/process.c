#include <neutron/platform/linux-platform.h>
#include <neutron/platform/linux-process.h>
#include <neutron/platform/platform.h>
#include <neutron/platform/process.h>
#include <sys/types.h>
#define __USE_GNU
#include <sys/ucontext.h>
#include <assert.h>
#include <setjmp.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <ucontext.h>
#include <unistd.h>
#include "process-priv.h"
#include "../../../src/process-priv.h"

NT_DEFINE_TYPE(NT, LINUX_PROCESS, NtLinuxProcess, nt_linux_process, NT_TYPE_FLAG_STATIC, NT_TYPE_PROCESS, NT_TYPE_NONE);

struct SignalContext {
  NtProcess* proc;
  struct sigaction old_sa;
  ucontext_t uctx;
  sigjmp_buf env;
};

#if defined(AARCH64)
#define CPU_ARG0 REG_X0
#elif defined(ARM)
#define CPU_ARG0 REG_R0
#elif defined(RISCV32)
#define CPU_ARG0 REG_A0
#elif defined(RISCV64)
#define CPU_ARG0 REG_A0
#elif defined(X86_64)
#define CPU_ARG0 REG_RAX
#elif defined(X86)
#define CPU_ARG0 REG_EAX
#else
#error "CPU not supported"
#endif

static int get_signal(NtException exception, NtInterrupt interrupt) {
  switch (exception) {
    case NT_PROCESS_EXCEPTION_NONE:
      break;
    case NT_PROCESS_EXCEPTION_SEG_VIO:
      return SIGSEGV;
    case NT_PROCESS_EXCEPTION_HW_BUS:
      return SIGBUS;
    case NT_PROCESS_EXCEPTION_ILL_INSTR:
      return SIGILL;
    case NT_PROCESS_EXCEPTION_ILL_MATH:
      return SIGFPE;
  }

  switch (interrupt) {
    case NT_PROCESS_INTERRUPT_NONE:
      break;
    case NT_PROCESS_INTERRUPT_DBG_STOP:
      return SIGSTOP;
    case NT_PROCESS_INTERRUPT_DBG_CONT:
      return SIGCONT;
    case NT_PROCESS_INTERRUPT_KILL:
      return SIGKILL;
    case NT_PROCESS_INTERRUPT_EXIT:
      return SIGHUP;
    case NT_PROCESS_INTERRUPT_QUIT:
      return SIGTERM;
  }
  return 0;
}

static void nt_linux_process_signal_handler(int sig, siginfo_t* info, void* uctx_ptr) {
  ucontext_t* uctx = uctx_ptr;
  struct SignalContext* ctx = info->si_value.sival_ptr;

  NtProcessSignal* sigdata = malloc(sizeof (NtProcessSignal));
  sigdata->address = info->si_addr;
  sigdata->stack = uctx->uc_stack.ss_sp;
  sigdata->is_return = false;
  sigdata->is_exception = false;
  sigdata->is_interrupt = false;

  switch (sig) {
    case SIGSEGV:
      sigdata->is_exception = true;
      sigdata->exception.kind = NT_PROCESS_EXCEPTION_SEG_VIO;
      break;
    case SIGBUS:
      sigdata->is_exception = true;
      sigdata->exception.kind = NT_PROCESS_EXCEPTION_HW_BUS;
      break;
    case SIGILL:
      sigdata->is_exception = true;
      sigdata->exception.kind = NT_PROCESS_EXCEPTION_ILL_INSTR;
      break;
    case SIGFPE:
      sigdata->is_exception = true;
      sigdata->exception.kind = NT_PROCESS_EXCEPTION_ILL_MATH;
      break;
    case SIGSTOP:
      sigdata->is_interrupt = true;
      sigdata->interrupt.kind = NT_PROCESS_INTERRUPT_DBG_STOP;
      break;
    case SIGCONT:
      sigdata->is_interrupt = true;
      sigdata->interrupt.kind = NT_PROCESS_INTERRUPT_DBG_CONT;
      break;
    case SIGKILL:
      sigdata->is_interrupt = true;
      sigdata->interrupt.kind = NT_PROCESS_INTERRUPT_KILL;
      break;
    case SIGHUP:
      sigdata->is_interrupt = true;
      sigdata->interrupt.kind = NT_PROCESS_INTERRUPT_EXIT;
      break;
    case SIGTERM:
      sigdata->is_interrupt = true;
      sigdata->interrupt.kind = NT_PROCESS_INTERRUPT_QUIT;
      break;
  }

  void* result = NULL;

  NtTypeArgument arguments[] = {
    { NT_TYPE_ARGUMENT_KEY(NtProcessSignal, signal), NT_VALUE_POINTER(sigdata) },
    { NT_TYPE_ARGUMENT_KEY(NtProcessSignal, result), NT_VALUE_POINTER(&result) },
    { NULL }
  };

  nt_signal_emit(ctx->proc->priv->signal, arguments);
  free(sigdata);

  if (sigdata->is_return) {
    ctx->uctx.uc_mcontext.gregs[CPU_ARG0] = (uintptr_t)sigdata->return_data.arg0;
  }

  sigaction(sig, &ctx->old_sa, NULL);
  siglongjmp(ctx->env, 1);
}

static bool nt_linux_process_is_current(NtProcess* proc) {
  NtLinuxProcess* self = NT_LINUX_PROCESS((NtTypeInstance*)proc);
  assert(self != NULL);

  return self->priv->pid == getpid();
}

static void* nt_linux_process_send_signal(NtProcess* proc, NtException exception, NtInterrupt interrupt) {
  NtLinuxProcess* self = NT_LINUX_PROCESS((NtTypeInstance*)proc);
  assert(self != NULL);

  int sig = get_signal(exception, interrupt);

  if (nt_process_is_current(proc)) {
    struct SignalContext* ctx = alloca(sizeof (struct SignalContext));
    ctx->proc = NT_PROCESS(self);

    struct sigaction act = {};
    act.sa_sigaction = nt_linux_process_signal_handler;
    act.sa_flags = SA_SIGINFO;
    assert(sigaction(sig, &act, &ctx->old_sa) == 0);

    union sigval value = {
      .sival_ptr = ctx
    };

    if (sigsetjmp(ctx->env, 1) == 0) {
      sigqueue(self->priv->pid, sig, value);
      sigaction(sig, &ctx->old_sa, NULL);
      return NULL;
    }
    return (void*)ctx->uctx.uc_mcontext.gregs[CPU_ARG0];
  }

  kill(self->priv->pid, sig);
  return NULL;
}

static void nt_linux_process_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtProcess* proc = NT_PROCESS(instance);
  assert(proc != NULL);

  NtLinuxProcess* self = NT_LINUX_PROCESS(instance);
  assert(self != NULL);

  proc->is_current = nt_linux_process_is_current;
  proc->send_signal = nt_linux_process_send_signal;

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
