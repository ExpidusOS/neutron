#include <neutron/elemental/backtrace.h>
#include "neutron-elemental-build.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAS_EXECINFO_H
#include <execinfo.h>
#endif

#define N_FRAMES 100

NT_DEFINE_TYPE(NT, BACKTRACE, NtBacktrace, nt_backtrace, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_backtrace_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtBacktrace* self = NT_BACKTRACE(instance);
  assert(self != NULL);
  self->entries = NULL;
}

static void nt_backtrace_destroy(NtTypeInstance* instance) {
  NtBacktrace* self = NT_BACKTRACE(instance);
  assert(self != NULL);

  for (NtBacktraceEntry* entry = self->entries; entry != NULL;) {
    NtBacktraceEntry* next = entry->prev;

    if (entry->file != NULL) free((char*)entry->file);
    if (entry->method != NULL) free((char*)entry->method);
    free(entry);

    entry = next;
  }
}

NtBacktrace* nt_backtrace_new() {
  return NT_BACKTRACE(nt_type_instance_new(NT_TYPE_BACKTRACE, NULL));
}

NtBacktrace* nt_backtrace_new_auto() {
  NtBacktrace* self = nt_backtrace_new();

#ifdef HAS_EXECINFO_H
  void* temp_frames[N_FRAMES];
  int n_frames = backtrace(temp_frames, N_FRAMES);

  void** frames = malloc(sizeof (void*) * n_frames);
  assert(frames != NULL);
  n_frames = backtrace(frames, n_frames);

  char** symbols = backtrace_symbols(frames, n_frames);
  assert(symbols != NULL);

  for (int i = 0; i < n_frames; i++) {
    nt_backtrace_push_full(self, NULL, symbols[i], 0, frames[i]);
  }

  free(frames);
  free(symbols);
#endif
  return self;
}

NtBacktrace* nt_backtrace_copy(NtBacktrace* self) {
  assert(NT_IS_BACKTRACE(self));

  NtBacktrace* child = nt_backtrace_new();
  assert(child != NULL);

  for (NtBacktraceEntry* entry = self->entries; entry != NULL; entry = entry->prev) {
    nt_backtrace_push_full(child, entry->file, entry->method, entry->line, entry->address);
  }
  return child;
}

void nt_backtrace_push_full(NtBacktrace* self, const char* file, const char* method, int line, void* address) {
  assert(NT_IS_BACKTRACE(self));

  NtBacktraceEntry* entry = malloc(sizeof (NtBacktraceEntry));
  assert(entry != NULL);
  entry->prev = self->entries;
  entry->file = file == NULL ? NULL : strdup(file);
  entry->method = method == NULL ? NULL : strdup(method);
  entry->line = line;
  entry->address = address;

  self->entries = entry;
}

void nt_backtrace_sync_full(NtBacktrace* self, int line) {
  assert(NT_IS_BACKTRACE(self));

  asset(self->entries != NULL);
  self->entries->line = line;
}

void nt_backtrace_pop(NtBacktrace* self) {
  assert(NT_IS_BACKTRACE(self));

  if (self->entries != NULL) {
    NtBacktraceEntry* prev = self->entries->prev;

    if (self->entries->file != NULL) free((char*)self->entries->file);
    if (self->entries->method != NULL) free((char*)self->entries->method);
    free(self->entries);

    self->entries = prev;
  } else {
    self->entries = NULL;
  }
}

NtString* nt_backtrace_to_string(NtBacktrace* self) {
  assert(NT_IS_BACKTRACE(self));

  NtString* string = nt_string_new(NULL);
  assert(string != NULL);

  NtString* str = nt_string_new(NULL);
  assert(str != NULL);

  size_t i = 0;
  for (NtBacktraceEntry* entry = self->entries; entry != NULL; entry = entry->prev) {
    nt_string_dynamic_printf(str, "%zu. %s:%d %s:%p\n", i++, entry->file, entry->line, entry->method, entry->address);

    const char* s = nt_string_get_value(str, NULL);
    assert(s != NULL);

    nt_string_dynamic_append(string, s);
    free((char*)s);
  }

  nt_type_instance_unref((NtTypeInstance*)str);
  return string;
}
