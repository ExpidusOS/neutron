#pragma once

#include <neutron/platform/process.h>

typedef struct _NtProcessSignal {
  NtProcess* proc;
  NtSignalHandler handler;
  void* data;
  NtSignalResult result;
} NtProcessSignal;

typedef struct _NtProcessPrivate {
  NtSignal* signal;
} NtProcessPrivate;
