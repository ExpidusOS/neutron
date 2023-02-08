#include <neutron/platform/systemd-device.h>
#include <assert.h>
#include <stdlib.h>
#include "device-priv.h"

NT_DEFINE_TYPE(NT, SYSTEMD_DEVICE, NtSystemdDevice, nt_systemd_device, NT_TYPE_FLAG_STATIC, NT_TYPE_DEVICE, NT_TYPE_NONE);

static void nt_systemd_device_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtSystemdDevice* self = NT_SYSTEMD_DEVICE(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtSystemdDevicePrivate));
  assert(self->priv != NULL);

  NtValue value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtSystemdDevice, device), NT_VALUE_POINTER(NULL));
  assert(value.type == NT_VALUE_TYPE_POINTER);
  assert(value.data.pointer != NULL);

  self->priv->device = sd_device_ref(value.data.pointer);
  assert(self->priv->device != NULL);
}

static void nt_systemd_device_destroy(NtTypeInstance* instance) {
  NtSystemdDevice* self = NT_SYSTEMD_DEVICE(instance);
  assert(self != NULL);

  sd_device_unref(self->priv->device);
  free(self->priv);
}

NtDevice* nt_systemd_device_new(sd_device* device) {
  return NT_DEVICE(nt_type_instance_new(NT_TYPE_SYSTEMD_DEVICE, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtSystemdDevice, device), NT_VALUE_POINTER(device) },
    { NULL }
  }));
}
