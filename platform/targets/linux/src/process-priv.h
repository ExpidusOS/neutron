#pragma once

#include <neutron/platform/linux-process.h>

typedef struct _NtLinuxProcessPrivate {
  pid_t pid;
} NtLinuxProcessPrivate;
