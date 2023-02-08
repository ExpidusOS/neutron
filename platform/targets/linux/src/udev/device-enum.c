#include <neutron/platform/udev-device-enum.h>
#include <assert.h>
#include <stdlib.h>
#include "device-enum-priv.h"

NT_DEFINE_TYPE(NT, UDEV_DEVICE_ENUM, NtUdevDeviceEnum, nt_udev_device_enum, NT_TYPE_FLAG_STATIC, NT_TYPE_DEVICE_ENUM, NT_TYPE_NONE);

static struct udev_enumerate* create_enumerate(NtUdevDeviceEnum* self, NtDeviceQuery query) {
  struct udev_enumerate* enumerate = udev_enumerate_new(self->priv->udev);
  return enumerate;
}

static size_t nt_udev_device_enum_count(NtDeviceEnum* device_enum, NtDeviceQuery query) {
  NtUdevDeviceEnum* self = NT_UDEV_DEVICE_ENUM((NtTypeInstance*)device_enum);
  assert(self != NULL);

  struct udev_enumerate* enumerate = create_enumerate(self, query);
  int i = udev_enumerate_scan_devices(enumerate);
  udev_enumerate_unref(enumerate);
  return i;
}

static void nt_udev_device_enum_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtDeviceEnum* device_enum = NT_DEVICE_ENUM(instance);
  assert(device_enum != NULL);

  NtUdevDeviceEnum* self = NT_UDEV_DEVICE_ENUM(instance);
  assert(self != NULL);

  device_enum->count = nt_udev_device_enum_count;

  self->priv = malloc(sizeof (NtUdevDeviceEnumPrivate));
  assert(self->priv != NULL);

  self->priv->udev = udev_new();
  assert(self->priv->udev != NULL);
}

static void nt_udev_device_enum_destroy(NtTypeInstance* instance) {
  NtUdevDeviceEnum* self = NT_UDEV_DEVICE_ENUM(instance);
  assert(self != NULL);

  udev_unref(self->priv->udev);
  free(self->priv);
}

NtDeviceEnum* nt_udev_device_enum_new() {
  return NT_DEVICE_ENUM(nt_type_instance_new(NT_TYPE_UDEV_DEVICE_ENUM, NULL));
}
