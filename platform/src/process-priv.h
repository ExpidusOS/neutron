#pragma once

#include <neutron/platform/platform.h>
#include <neutron/platform/process.h>

typedef struct _NtProcessSignalEntry {
  NtProcess* proc;
  NtProcessSignalHandler handler;
  const void* data;
  NtProcessSignalResult result;
} NtProcessSignalEntry;

typedef struct _NtProcessPrivate {
  NtSignal* signal;
  NtPlatform* platform;
} NtProcessPrivate;
