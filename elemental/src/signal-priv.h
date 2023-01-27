#pragma once

#include <neutron/elemental/signal.h>
#include <pthread.h>

typedef struct _NtSignalEntry {
  struct _NtSignalEntry* prev;
  NtSignalHandler handler;
  const void* user_data;
  struct _NtSignalEntry* next;
} NtSignalEntry;

typedef struct _NtSignalPrivate {
  bool is_locking;
  pthread_mutex_t mutex;

  NtSignalEntry* entries;
} NtSignalPrivate;
