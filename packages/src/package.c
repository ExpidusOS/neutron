#include <neutron/packages/package.h>
#include <assert.h>
#include "package-priv.h"
#include <stdlib.h>
#include <string.h>

NT_DEFINE_TYPE(NT, PACKAGE, NtPackage, nt_package, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_package_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtPackage* self = NT_PACKAGE(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtPackagePrivate));
  assert(self->priv != NULL);
  memset(self->priv, 0, sizeof (NtPackagePrivate));

  NtValue value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtPackage, path), NT_VALUE_STRING(NULL));
  assert(value.type == NT_VALUE_TYPE_STRING);
  assert(value.data.string != NULL);

  self->priv->path = strdup(value.data.string);
}

static void nt_package_destroy(NtTypeInstance* instance) {
  NtPackage* self = NT_PACKAGE(instance);
  assert(self != NULL);

  free((char*)self->priv->path);
  free(self->priv);
}

NtPackage* nt_package_new(const char* path) {
  return NT_PACKAGE(nt_type_instance_new(NT_TYPE_PACKAGE, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtPackage, path), NT_VALUE_STRING((char*)path) },
    { NULL }
  }));
}
