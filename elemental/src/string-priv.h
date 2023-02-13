#pragma once

#include <neutron/elemental/string.h>

typedef struct _NtStringPrivate {
  size_t length;
  char* value;
} NtStringPrivate;
