#include <neutron/elemental/type.h>
#include <assert.h>
#include <pthread.h>
#include <stdlib.h>

struct TypeEntry {
  struct TypeEntry* prev;
  const NtTypeInfo* info;
  struct TypeEntry* next;
};

static NtType nt_type_next_id = 1;
static pthread_mutex_t nt_type_mutex;
static struct TypeEntry* nt_type_registry;

NT_EXPORT NtType nt_type_register(NtTypeInfo* info) {
  assert(info != NULL);
  assert(info->id == 0);

  pthread_mutex_lock(&nt_type_mutex);

  // TODO: check if type is already registered in registry

  info->id = nt_type_next_id++;

  struct TypeEntry* entry = malloc(sizeof (struct TypeEntry));
  assert(entry != NULL);
  entry->info = info;
  entry->next = nt_type_registry;

  if (nt_type_registry != NULL) {
    nt_type_registry->prev = entry;
  }

  nt_type_registry = entry;

  pthread_mutex_unlock(&nt_type_mutex);
  return info->id;
}

NT_EXPORT void nt_type_unregister(NtTypeInfo* info) {
  for (struct TypeEntry* item = nt_type_registry; item != NULL; item = item->next) {
    if (item->info->id == info->id) {
      pthread_mutex_lock(&nt_type_mutex);

      item->prev->next = item->next;
      item->next->prev = item->prev;

      free(item);
      pthread_mutex_unlock(&nt_type_mutex);
      break;
    }
  }
}

NT_EXPORT const NtTypeInfo* nt_type_info_from_type(NtType type) {
  for (struct TypeEntry* item = nt_type_registry; item != NULL; item = item->next) {
    if (item->info->id == type) {
      return item->info;
    }
  }
  return NULL;
}
