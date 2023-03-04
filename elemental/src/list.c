#include <neutron/elemental/argument.h>
#include <neutron/elemental/list.h>
#include <assert.h>
#include <stdlib.h>

NT_DEFINE_TYPE(NT, LIST, NtList, nt_list, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_list_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtList* self = NT_LIST(instance);
  assert(self != NULL);

  NtValue prev = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtList, prev), NT_VALUE_INSTANCE(NULL));
  assert(prev.type == NT_VALUE_TYPE_INSTANCE);
  if (prev.data.instance != NULL) {
    assert(NT_IS_LIST((NtList*)prev.data.instance));
    self->prev = NT_LIST(prev.data.instance);
    self->prev->next = self;
  }

  NtValue next = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtList, next), NT_VALUE_INSTANCE(NULL));
  assert(next.type == NT_VALUE_TYPE_INSTANCE);
  assert(NT_IS_LIST((NtList*)next.data.instance));
  if (next.data.instance != NULL) {
    self->next = NT_LIST(next.data.instance);
    self->next->prev = self;
  }

  NtValue value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtList, value), NT_VALUE_POINTER(NULL));
  self->value = value;
}

static void nt_list_destroy(NtTypeInstance* instance) {
  NtList* self = NT_LIST(instance);
  assert(self != NULL);

  if (self->prev != NULL) self->prev->next = self->next;
  if (self->next != NULL) self->next->prev = self->prev;
}

NtList* nt_list_alloc(NtValue value) {
  return NT_LIST(nt_type_instance_new(NT_TYPE_LIST, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtList, value), value },
    { NULL }
  }));
}

NtList* nt_list_get_head(NtList* self) {
  if (self == NULL) return NULL;
  assert(NT_IS_LIST(self));

  while (self->prev != NULL) self = self->prev;
  return self;
}

NtList* nt_list_get_tail(NtList* self) {
  if (self == NULL) return NULL;
  assert(NT_IS_LIST(self));

  while (self->next != NULL) self = self->next;
  return self;
}

size_t nt_list_length(NtList* self) {
  if (self == NULL) return 0;

  size_t i = 1;
  while (self->next != NULL) {
    i++;
    self = self->next;
  }
  return i;
}

NtList* nt_list_prepend(NtList* self, NtValue value) {
  NtList* head = nt_list_get_head(self);
  NtList* item = nt_list_alloc(value);

  item->next = head;
  if (head != NULL) head->prev = item;
  return item;
}

NtList* nt_list_append(NtList* self, NtValue value) {
  NtList* tail = nt_list_get_tail(self);
  NtList* item = nt_list_alloc(value);

  item->prev = tail;
  if (tail != NULL) {
    tail->next = item;
    return tail;
  }
  return item;
}
