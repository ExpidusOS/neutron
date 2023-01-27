#include <neutron/elemental/signal.h>
#include "signal-priv.h"
#include <assert.h>
#include <string.h>

NT_DEFINE_TYPE(NT, SIGNAL, NtSignal, nt_signal, NT_TYPE_FLAG_STATIC);

static void nt_signal_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtSignal* self = NT_SIGNAL(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtSignalPrivate));
  assert(self->priv != NULL);
  memset(self->priv, 0, sizeof (NtSignalPrivate));

  NtValue locking = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtSignal, locking), NT_VALUE_BOOL(false));
  assert(locking.type == NT_VALUE_TYPE_BOOL);
  self->priv->is_locking = locking.data.boolean;

  assert(pthread_mutex_init(&self->priv->mutex, NULL) == 0);
}

static void nt_signal_destroy(NtTypeInstance* instance) {
  NtSignal* self = NT_SIGNAL(instance);
  assert(self != NULL);

  for (NtSignalEntry* entry = self->priv->entries; entry != NULL;) {
    NtSignalEntry* next = entry->next;
    free(entry);
    entry = next;
  }

  pthread_mutex_destroy(&self->priv->mutex);
  free(self->priv);
}

NtSignal* nt_signal_new() {
  return NT_SIGNAL(nt_type_instance_new(NT_TYPE_SIGNAL, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtSignal, locking), NT_VALUE_BOOL(false) },
    { NULL }
  }));
}

NtSignal* nt_signal_new_locking() {
  return NT_SIGNAL(nt_type_instance_new(NT_TYPE_SIGNAL, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtSignal, locking), NT_VALUE_BOOL(true) },
    { NULL }
  }));
}

void nt_signal_attach(NtSignal* self, NtSignalHandler handler, const void* data) {
  assert(NT_IS_SIGNAL(self));
  assert(handler != NULL);

  pthread_mutex_lock(&self->priv->mutex);

  NtSignalEntry* entry = malloc(sizeof (NtSignalEntry));
  assert(entry != NULL);
  entry->handler = handler;
  entry->user_data = data;
  entry->next = self->priv->entries;
  if (self->priv->entries != NULL) self->priv->entries->prev = entry;
  self->priv->entries = entry;

  pthread_mutex_unlock(&self->priv->mutex);
}

void nt_signal_detach(NtSignal* self, NtSignalHandler handler) {
  assert(NT_IS_SIGNAL(self));
  assert(handler != NULL);

  for (NtSignalEntry* entry = self->priv->entries; entry != NULL; entry = entry->next) {
    if (entry->handler == handler) {
      pthread_mutex_lock(&self->priv->mutex);

      if (entry->prev != NULL) entry->prev->next = entry->next;
      if (entry->next != NULL) entry->next->prev = entry->prev;
      free(entry);

      pthread_mutex_unlock(&self->priv->mutex);
      break;
    }
  }
}

void nt_signal_emit(NtSignal* self, NtTypeArgument* arguments) {
  assert(NT_IS_SIGNAL(self));

  if (self->priv->is_locking) pthread_mutex_lock(&self->priv->mutex);

  for (NtSignalEntry* entry = self->priv->entries; entry != NULL; entry = entry->next) {
    assert(entry->handler != NULL);
    entry->handler(self, arguments, entry->user_data);
  }

  if (self->priv->is_locking) pthread_mutex_unlock(&self->priv->mutex);
}
