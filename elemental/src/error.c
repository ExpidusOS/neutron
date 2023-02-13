#include <neutron/elemental/argument.h>
#include <neutron/elemental/error.h>
#include "error-priv.h"
#include <assert.h>
#include <string.h>

NT_DEFINE_TYPE(NT, ERROR, NtError, nt_error, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_error_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtError* self = NT_ERROR(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtErrorPrivate));
  assert(self->priv != NULL);

  NtValue file = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtError, file), NT_VALUE_STRING(NULL));
  assert(file.type == NT_VALUE_TYPE_STRING);
  self->priv->file = file.data.string == NULL ? NULL : strdup(file.data.string);

  NtValue method = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtError, method), NT_VALUE_STRING(NULL));
  assert(method.type == NT_VALUE_TYPE_STRING);
  self->priv->method = method.data.string == NULL ? NULL : strdup(method.data.string);

  NtValue line = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtError, line), NT_VALUE_NUMBER(0));
  assert(line.type == NT_VALUE_TYPE_NUMBER);
  self->priv->line = line.data.number;

  NtValue message = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtError, message), NT_VALUE_STRING(NULL));
  assert(message.type == NT_VALUE_TYPE_STRING);
  self->priv->message = message.data.string == NULL ? NULL : strdup(message.data.string);

  NtValue backtrace = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtError, backtrace), NT_VALUE_INSTANCE(NULL));
  assert(backtrace.type == NT_VALUE_TYPE_INSTANCE);
  self->priv->backtrace = NULL;

  if (backtrace.data.instance != NULL) {
    assert(NT_IS_BACKTRACE((void*)backtrace.data.instance));
    self->priv->backtrace = nt_backtrace_copy(NT_BACKTRACE(backtrace.data.instance));
    assert(self->priv->backtrace != NULL);
  }
}

static void nt_error_destroy(NtTypeInstance* instance) {
  NtError* self = NT_ERROR(instance);
  assert(self != NULL);

  if (self->priv->backtrace != NULL) {
    nt_type_instance_unref((NtTypeInstance*)self->priv->backtrace);
  }

  free(self->priv);
}

NtError* nt_error_new_full(const char* file, const char* method, int line, const char* message, NtBacktrace* backtrace) {
  return NT_ERROR(nt_type_instance_new(NT_TYPE_ERROR, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtError, file), NT_VALUE_STRING((char*)file) },
    { NT_TYPE_ARGUMENT_KEY(NtError, method), NT_VALUE_STRING((char*)method) },
    { NT_TYPE_ARGUMENT_KEY(NtError, line), NT_VALUE_NUMBER(line) },
    { NT_TYPE_ARGUMENT_KEY(NtError, message), NT_VALUE_STRING((char*)message) },
    { NT_TYPE_ARGUMENT_KEY(NtError, backtrace), NT_VALUE_INSTANCE((NtTypeInstance*)backtrace) },
    { NULL }
  }));
}
