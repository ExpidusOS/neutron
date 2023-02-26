#include <neutron/elemental/fs.h>
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

const char* nt_join_path(const char* prefix, ...) {
  va_list ap;
  va_start(ap, prefix);

  const char* value = nt_join_pathv(prefix, ap);
  va_end(ap);
  return value;
}

const char* nt_join_pathv(const char* prefix, va_list ap) {
  NtString* str = nt_string_new(NULL);
  assert(str != NULL);

  while (prefix != NULL) {
#if defined(WINDOWS) || defined(CYGWIN)
    char* d = "\\";
#else
    char* d = "/";
#endif

    nt_string_dynamic_append(str, d);
    nt_string_dynamic_append(str, prefix);
    prefix = va_arg(ap, char*);
  }

  const char* s = nt_string_get_value(str, NULL);
  nt_type_instance_unref((NtTypeInstance*)str);
  return s;
}

const char* nt_read_file(const char* path, NtBacktrace* backtrace, NtError** error) {
  assert(NT_IS_BACKTRACE(backtrace));
  assert(error != NULL && *error == NULL);

  nt_backtrace_push(backtrace, nt_read_file);

  FILE* fp = fopen(path, "rb");
  if (fp == NULL) {
    NtString* str = nt_string_new(NULL);
    assert(str != NULL);

    int e = errno;
    nt_string_dynamic_printf(str, "Failed to open \"%s\": (%d) %s", path, e, strerror(e));

    const char* s = nt_string_get_value(str, NULL);
    assert(s != NULL);
    nt_type_instance_unref((NtTypeInstance*)str);

    *error = nt_error_new(s, backtrace);
    free((char*)s);
    nt_backtrace_pop(backtrace);
    return NULL;
  }

  fseek(fp, 0, SEEK_END);
  size_t length = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  char* buff = malloc(length);
  assert(buff != NULL);

  assert(fread(buff, 1, length, fp) == length);

  fclose(fp);
  nt_backtrace_pop(backtrace);
  return buff;
}
