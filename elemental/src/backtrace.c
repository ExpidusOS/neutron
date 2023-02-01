#include <neutron/elemental/backtrace.h>
#include <assert.h>
#include <execinfo.h>
#include <stdlib.h>
#include <string.h>

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
  return self;
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
