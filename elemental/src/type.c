#include <neutron/elemental/type.h>
#include <assert.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

struct TypeEntry {
  struct TypeEntry* prev;
  const NtTypeInfo* info;
  struct TypeEntry* next;
};

static NtType nt_type_next_id = 1;
static pthread_mutex_t nt_type_mutex;
static struct TypeEntry* nt_type_registry = NULL;

#define NT_TYPE_INFO_IS_VALID(info) ((info) != NULL && (info)->id > 0)

NT_EXPORT NtType nt_type_register(NtTypeInfo* info) {
  assert(info != NULL);
  assert(info->id == 0);

  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);
      assert(subinfo->flags & NT_TYPE_FLAG_DYNAMIC);
    }
  }

  pthread_mutex_lock(&nt_type_mutex);

  // TODO: check if type is already registered in registry

  info->id = nt_type_next_id++;

  struct TypeEntry* entry = malloc(sizeof (struct TypeEntry));
  assert(entry != NULL);
  memset(entry, 0, sizeof (struct TypeEntry));
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
  assert(NT_TYPE_INFO_IS_VALID(info));

  for (struct TypeEntry* item = nt_type_registry; item != NULL; item = item->next) {
    if (item->info->id == info->id) {
      pthread_mutex_lock(&nt_type_mutex);

      if (item->prev != NULL) item->prev->next = item->next;
      if (item->next != NULL) item->next->prev = item->prev;
      free(item);

      pthread_mutex_unlock(&nt_type_mutex);
      info->id = 0;
      break;
    }
  }
}

NT_EXPORT bool nt_type_isof(NtType type, NtType base) {
  assert(type != NT_TYPE_NONE);
  assert(base != NT_TYPE_NONE);

  const NtTypeInfo* info = nt_type_info_from_type(type);
  assert(info != NULL);

  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      if (info->extends[i] == base) return true;

      bool r = nt_type_isof(info->extends[i], base);
      if (r) return true;
    }
  }
  return false;
}

NT_EXPORT const NtTypeInfo* nt_type_info_from_type(NtType type) {
  for (struct TypeEntry* item = nt_type_registry; item != NULL; item = item->next) {
    if (item->info->id == type) {
      return item->info;
    }
  }
  return NULL;
}

NT_EXPORT const size_t nt_type_info_get_total_size(NtTypeInfo* info) {
  assert(NT_TYPE_INFO_IS_VALID(info));

  size_t size = info->size;

  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);
      size += (size_t)nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }
  return size;
}

NT_EXPORT NtTypeInstance* nt_type_instance_new(NtType type) {
  const NtTypeInfo* info = nt_type_info_from_type(type);
  assert(info != NULL);

  const size_t data_size = nt_type_info_get_total_size((NtTypeInfo*)info);
  const size_t size = sizeof (NtTypeInstance) + data_size;
  assert(size >= sizeof (NtTypeInstance));

  NtTypeInstance* instance = malloc(size);
  assert(instance != NULL);
  memset(instance, 0, size);

  instance->info = info;
  instance->data = instance + sizeof (NtTypeInstance);
  instance->data_size = data_size;

  size_t off = 0;

  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      // TODO: recursively do this for all subinfo children extends
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);

      if (subinfo->construct != NULL) {
        subinfo->construct(instance, instance->data + off);
      }

      off += nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }

  if (info->construct != NULL) {
    info->construct(instance, instance->data + off);
  }
  return instance;
}

NT_EXPORT void* nt_type_instance_get_data(NtTypeInstance* instance, NtType type) {
  size_t off = 0;

  if (instance->info->extends != NULL) {
    for (size_t i = 0; instance->info->extends[i] != NT_TYPE_NONE; i++) {
      // TODO: recursively do this for all subinfo children extends
      if (instance->info->extends[i] != type) {
        const NtTypeInfo* subinfo = nt_type_info_from_type(instance->info->extends[i]);
        assert(subinfo != NULL);
        off += nt_type_info_get_total_size((NtTypeInfo*)subinfo);
        continue;
      }
      return (void*)(instance->data + off);
    }
  }
  return NULL;
}

NT_EXPORT NtTypeInstance* nt_type_instance_ref(NtTypeInstance* instance) {
  if (instance->info->flags & NT_TYPE_FLAG_NOREF) return instance;

  instance->ref_count++;
  return instance;
}

NT_EXPORT void nt_type_instance_destroy(NtTypeInstance* instance) {
  if (instance->ref_count > 0) {
    instance->ref_count--;
    return;
  }

  size_t off = 0;

  if (instance->info->extends != NULL) {
    for (size_t i = 0; instance->info->extends[i] != NT_TYPE_NONE; i++) {
      // TODO: recursively do this for all subinfo children extends
      const NtTypeInfo* subinfo = nt_type_info_from_type(instance->info->extends[i]);
      assert(subinfo != NULL);

      if (subinfo->destroy != NULL) {
        subinfo->destroy(instance, instance->data + off);
      }

      off += nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }

  if (instance->info->destroy != NULL) {
    instance->info->destroy(instance, instance->data + off);
  }

  free(instance);
}
