#include <neutron/elemental/string.h>
#include <neutron/elemental/value.h>
#include "string-priv.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

NT_DEFINE_TYPE(NT, STRING, NtString, nt_string, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_string_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtString* self = NT_STRING(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtStringPrivate));
  assert(self->priv != NULL);
  memset(self->priv, 0, sizeof (NtStringPrivate));

  NtValue value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtString, length), NT_VALUE_NUMBER(0));
  assert(value.type == NT_VALUE_TYPE_NUMBER);
  self->priv->length = value.data.number;

  value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtString, value), NT_VALUE_STRING(NULL));
  if (value.data.string != NULL) self->priv->value = strdup(value.data.string);
}

static void nt_string_destroy(NtTypeInstance* instance) {
  NtString* self = NT_STRING(instance);
  assert(self != NULL);

  if (self->priv->value != NULL) free(self->priv->value);
  free(self->priv);
}

NtString* nt_string_new(char* value) {
  return nt_string_new_full(value, value == NULL ? 0 : strlen(value));
}

NtString* nt_string_new_alloc(size_t length, char c) {
  char* value = malloc(length);
  assert(length > 0 && value != NULL);
  if (value != NULL) memset(value, c, length);

  NtString* self = nt_string_new_full(value, length);
  if (value != NULL) free(value);
  return self;
}

NtString* nt_string_new_full(char* value, size_t length) {
  return NT_STRING(nt_type_instance_new(NT_TYPE_STRING, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtString, length), NT_VALUE_NUMBER(length) },
    { NT_TYPE_ARGUMENT_KEY(NtString, value), NT_VALUE_STRING(value) },
    { NULL }
  }));
}

void nt_string_set_dynamic(NtString* self, const char* value) {
  assert(NT_IS_STRING(self));

  if (self->priv->value != NULL) {
    self->priv->length = 0;
    free(self->priv->value);
  }

  self->priv->length = value == NULL ? 0 : strlen(value);
  self->priv->value = value == NULL ? NULL : strdup(value);
  self->priv->value[self->priv->length] = 0;
}

void nt_string_set_fixed(NtString* self, const char* value) {
  assert(NT_IS_STRING(self));
  assert(self->priv->value != NULL);
  assert(value != NULL);

  size_t value_length = strlen(value);
  size_t n_over = value_length - self->priv->length;
  strncpy(self->priv->value, value, n_over > 0 ? self->priv->length : value_length);
  self->priv->value[self->priv->length] = 0;
}

void nt_string_set_fixed_strict(NtString* self, const char* value) {
  assert(NT_IS_STRING(self));
  assert(self->priv->value != NULL);
  assert(value != NULL);
  assert(self->priv->length < strlen(value));

  strncpy(self->priv->value, value, strlen(value));
  self->priv->value[self->priv->length] = 0;
}

void nt_string_dynamic_printf(NtString* self, const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  nt_string_dynamic_vprintf(self, fmt, ap);
  va_end(ap);
}

void nt_string_fixed_printf(NtString* self, const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  nt_string_fixed_vprintf(self, fmt, ap);
  va_end(ap);
}

void nt_string_dynamic_vprintf(NtString* self, const char* fmt, va_list ap) {
  assert(NT_IS_STRING(self));

  va_list ap_copy;
  va_copy(ap_copy, ap);

  char tmp[1];
  size_t len = vsnprintf(tmp, sizeof (tmp), fmt, ap);
  len++;

  char* str = malloc(sizeof (char) * len);
  assert(str != NULL);

  size_t new_len = vsnprintf(str, len, fmt, ap_copy);
  new_len++;
  assert(len == new_len);

  if (self->priv->value != NULL) {
    self->priv->length = 0;
    free(self->priv->value);
  }

  self->priv->value = str;
  self->priv->length = new_len;
}

void nt_string_fixed_vprintf(NtString* self, const char* fmt, va_list ap) {
  assert(NT_IS_STRING(self));

  size_t len = vsnprintf(self->priv->value, self->priv->length, fmt, ap);
  assert(len < self->priv->length);
}

void nt_string_fixed_append(NtString* self, const char* str) {
  assert(NT_IS_STRING(self));
  assert(str != NULL);

  const char* val = nt_string_get_value(self, NULL);
  if (val == NULL) val = strdup("");

  nt_string_fixed_printf(self, "%s%s", val, str);
  free((char*)val);
}

void nt_string_dynamic_append(NtString* self, const char* str) {
  assert(NT_IS_STRING(self));
  assert(str != NULL);

  const char* val = nt_string_get_value(self, NULL);
  if (val == NULL) val = strdup("");

  nt_string_dynamic_printf(self, "%s%s", val, str);
  free((char*)val);
}

void nt_string_fixed_prepend(NtString* self, const char* str) {
  assert(NT_IS_STRING(self));
  assert(str != NULL);

  const char* val = nt_string_get_value(self, NULL);
  if (val == NULL) val = strdup("");

  nt_string_fixed_printf(self, "%s%s", str, val);
  free((char*)val);
}

void nt_string_dynamic_prepend(NtString* self, const char* str) {
  assert(NT_IS_STRING(self));
  assert(str != NULL);

  const char* val = nt_string_get_value(self, NULL);
  if (val == NULL) val = strdup("");

  nt_string_dynamic_printf(self, "%s%s", str, val);
  free((char*)val);
}

const char* nt_string_get_value(NtString* self, size_t* length) {
  assert(NT_IS_STRING(self));

  if (length != NULL) *length = self->priv->length;
  if (self->priv->value != NULL) {
    char* value = strdup(self->priv->value);
    assert(value != NULL);

    value[self->priv->length] = 0;
    return value;
  }
  return NULL;
}

size_t nt_string_get_length(NtString* self) {
  assert(NT_IS_STRING(self));
  return self->priv->length;
}

bool nt_string_has_prefix(NtString* self, const char* prefix) {
  assert(NT_IS_STRING(self));
  assert(prefix != NULL);

  size_t prefix_len = strlen(prefix);
  if (prefix_len > self->priv->length) return false;
  return strncmp(self->priv->value, prefix, prefix_len) == 0;
}

bool nt_string_has_suffix(NtString* self, const char* suffix) {
  assert(NT_IS_STRING(self));
  assert(suffix != NULL);

  size_t suffix_len = strlen(suffix);
  if (suffix_len > self->priv->length) return false;
  return strncmp(self->priv->value + (self->priv->length - suffix_len), suffix, suffix_len) == 0;
}