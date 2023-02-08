#include <neutron/elemental/type.h>
#include <assert.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

struct TypeEntry {
  struct TypeEntry* prev;
  NtTypeInfo info;
  struct TypeEntry* next;
};

static NtType nt_type_next_id = 1;
static pthread_mutex_t nt_type_mutex;
static struct TypeEntry* nt_type_registry = NULL;

#define NT_TYPE_INFO_IS_VALID(info) ((info) != NULL && (info)->id > 0)

NtType nt_type_register(NtTypeInfo* info) {
  assert(info != NULL);
  assert(info->id == 0);

  size_t n_extends = 1;
  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);

      // FIXME: This check is not working as expected
      // assert(subinfo->flags & NT_TYPE_FLAG_DYNAMIC);
      n_extends++;
    }
  }

  pthread_mutex_lock(&nt_type_mutex);

  // TODO: check if type is already registered in registry

  info->id = nt_type_next_id++;

  struct TypeEntry* entry = malloc(sizeof (struct TypeEntry));
  assert(entry != NULL);
  memset(entry, 0, sizeof (struct TypeEntry));
  entry->next = nt_type_registry;

  entry->info.id = info->id;
  entry->info.flags = info->flags;
  entry->info.construct = info->construct;
  entry->info.destroy = info->destroy;
  entry->info.size = info->size;
  entry->info.sname = info->sname;

  entry->info.extends = calloc(n_extends, sizeof (NtType));
  if (info->extends != NULL) {
    assert(entry->info.extends != NULL);
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      entry->info.extends[i] = info->extends[i];
    }
  }

  entry->info.extends[n_extends - 1] = NT_TYPE_NONE;

  if (nt_type_registry != NULL) {
    nt_type_registry->prev = entry;
  }

  nt_type_registry = entry;

  pthread_mutex_unlock(&nt_type_mutex);
  return info->id;
}

void nt_type_unregister(NtTypeInfo* info) {
  assert(NT_TYPE_INFO_IS_VALID(info));

  for (struct TypeEntry* item = nt_type_registry; item != NULL; item = item->next) {
    if (item->info.id == info->id) {
      pthread_mutex_lock(&nt_type_mutex);

      if (item == nt_type_registry) nt_type_registry = item->next;
      if (item->prev != NULL) item->prev->next = item->next;
      if (item->next != NULL) item->next->prev = item->prev;

      free(item->info.extends);
      free(item);

      pthread_mutex_unlock(&nt_type_mutex);
      info->id = 0;
    }
  }
}

bool nt_type_isof(NtType type, NtType base) {
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

const NtTypeInfo* nt_type_info_from_type(NtType type) {
  for (struct TypeEntry* item = nt_type_registry; item != NULL; item = item->next) {
    if (item->info.id == type) {
      return &item->info;
    }
  }
  return NULL;
}

const size_t nt_type_info_get_total_size(NtTypeInfo* info) {
  assert(NT_TYPE_INFO_IS_VALID(info));

  size_t size = sizeof (NtTypeInstance) + info->size;

  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);
      size += (size_t)nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }
  return size;
}

static void nt_type_instance_flat_new(NtTypeInstance* instance, NtTypeInstance* prev, NtType type, NtTypeArgument* arguments) {
  const NtTypeInfo* info = nt_type_info_from_type(type);
  assert(info != NULL);

  const size_t data_size = nt_type_info_get_total_size((NtTypeInfo*)info);
  assert(data_size >= sizeof (NtTypeInstance));

  instance->type = type;
  instance->data_size = data_size;
  instance->ref_count = 0;
  instance->prev = prev;

  size_t off = sizeof (NtTypeInstance) + info->size;

  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);

      nt_type_instance_flat_new((void*)(instance + off), instance, subinfo->id, arguments);
      off += nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }

  if (info->construct != NULL) {
    info->construct(instance, arguments);
  }
}

NtTypeInstance* nt_type_instance_new(NtType type, NtTypeArgument* arguments) {
  const NtTypeInfo* info = nt_type_info_from_type(type);
  assert(info != NULL);

  const size_t size = nt_type_info_get_total_size((NtTypeInfo*)info);
  assert(size >= sizeof (NtTypeInstance));

  NtTypeInstance* instance = malloc(size);
  assert(instance != NULL);
  nt_type_instance_flat_new(instance, NULL, info->id, arguments);
  return instance;
}

NtTypeInstance* nt_type_instance_get_data(NtTypeInstance* instance, NtType type) {
  assert(instance != NULL);
  while (instance->prev != NULL) instance = instance->prev;

  const NtTypeInfo* info = nt_type_info_from_type(instance->type);
  assert(info != NULL);

  size_t off = info->size + sizeof (NtTypeInstance);
  if (info->extends != NULL) {
    for (size_t i = 0; info->extends[i] != NT_TYPE_NONE; i++) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[i]);
      assert(subinfo != NULL);

      if (subinfo->id == type) return (NtTypeInstance*)(instance + off);

      NtTypeInstance* subinst = nt_type_instance_get_data((NtTypeInstance*)(instance + off), type);
      if (subinst != NULL) return subinst;

      off += nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }
  
  if (info->id == type) return instance;
  return NULL;
}

NtTypeInstance* nt_type_instance_ref(NtTypeInstance* instance) {
  assert(instance != NULL);

  const NtTypeInfo* info = nt_type_info_from_type(instance->type);
  assert(info != NULL);
  if (info->flags & NT_TYPE_FLAG_NOREF) return instance;

  instance->ref_count++;
  return instance;
}

static void nt_type_instance_flat_destroy(NtTypeInstance* instance) {
  const NtTypeInfo* info = nt_type_info_from_type(instance->type);
  assert(info != NULL);

  if (info->destroy != NULL) {
    info->destroy(instance);
  }
  
  size_t off = info->size + sizeof (NtTypeInstance);

  if (info->extends != NULL) {
    size_t count = 0;
    for (; info->extends[count] != NT_TYPE_NONE; count++);

    while ((count--) > 0) {
      const NtTypeInfo* subinfo = nt_type_info_from_type(info->extends[count]);
      assert(subinfo != NULL);

      nt_type_instance_flat_destroy((void*)(instance + off));
      off += nt_type_info_get_total_size((NtTypeInfo*)subinfo);
    }
  }
}

void nt_type_instance_unref(NtTypeInstance* instance) {
  assert(instance != NULL);
  while (instance->prev != NULL) instance = instance->prev;

  if (instance->ref_count > 0) {
    instance->ref_count--;
    return;
  }

  nt_type_instance_flat_destroy(instance);
  free(instance);
}
