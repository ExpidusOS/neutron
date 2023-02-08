#pragma once

#include <neutron/elemental/pthread.h>
#include <neutron/elemental/signal.h>

typedef struct _NtSignalEntry {
  struct _NtSignalEntry* prev;
  int id;
  NtSignalHandler handler;
  const void* user_data;
  struct _NtSignalEntry* next;
} NtSignalEntry;

typedef struct _NtSignalPrivate {
  int next_id;
  bool is_locking;
  pthread_mutex_t mutex;

  NtSignalEntry* entries;
} NtSignalPrivate;
