#include <neutron/packages/metadata.h>
#include <assert.h>
#include "metadata-priv.h"
#include <stdlib.h>
#include <string.h>

NT_DEFINE_TYPE(NT, PACKAGE_METADATA, NtPackageMetadata, nt_package_metadata, NT_TYPE_FLAG_STATIC, NT_TYPE_NONE);

static void nt_package_metadata_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtPackageMetadata* self = NT_PACKAGE_METADATA(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtPackageMetadataPrivate));
  assert(self->priv != NULL);
  memset(self->priv, 0, sizeof (NtPackageMetadataPrivate));

  NtValue value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtPackageMetadata, path), NT_VALUE_STRING(NULL));
  assert(value.type == NT_VALUE_TYPE_STRING);
  assert(value.data.string != NULL);

  self->priv->path = strdup(value.data.string);
}

static void nt_package_metadata_destroy(NtTypeInstance* instance) {
  NtPackageMetadata* self = NT_PACKAGE_METADATA(instance);
  assert(self != NULL);

  free((char*)self->priv->path);
  free(self->priv);
}

NtPackageMetadata* nt_package_metadata_new(const char* path) {
  return NT_PACKAGE_METADATA(nt_type_instance_new(NT_TYPE_PACKAGE_METADATA, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtPackageMetadata, path), NT_VALUE_STRING((char*)path) },
    { NULL }
  }));
}
