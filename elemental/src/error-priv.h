#pragma once

#include <neutron/elemental/error.h>

typedef struct _NtErrorPrivate {
  const char* file;
  const char* method;
  int line;
  const char* message;
  NtBacktrace* backtrace;
} NtErrorPrivate;
