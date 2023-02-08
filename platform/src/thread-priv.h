#pragma once

#include <neutron/platform/thread.h>

typedef struct _NtThreadPrivate {
  NtSignal* signal;
  NtThreadClosure main;
} NtThreadPrivate;

void* nt_thread_exec(NtThread* self);
