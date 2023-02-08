#include <neutron/platform/systemd-device-enum.h>
#include <neutron/platform/systemd-device.h>
#include <assert.h>
#include <stdlib.h>
#include "device-enum-priv.h"

NT_DEFINE_TYPE(NT, SYSTEMD_DEVICE_ENUM, NtSystemdDeviceEnum, nt_systemd_device_enum, NT_TYPE_FLAG_STATIC, NT_TYPE_DEVICE_ENUM, NT_TYPE_NONE);

static sd_device_enumerator* create_enumerator(NtSystemdDeviceEnum* self, NtDeviceQuery query) {
  sd_device_enumerator* e = NULL;
  sd_device_enumerator_new(&e);
  return e;
}

static size_t nt_systemd_device_enum_count(NtDeviceEnum* device_enum, NtDeviceQuery query) {
  NtSystemdDeviceEnum* self = NT_SYSTEMD_DEVICE_ENUM((NtTypeInstance*)device_enum);
  assert(self != NULL);

  sd_device_enumerator* e = create_enumerator(self, query);
  
  sd_device* dev = NULL;
  size_t i = 0;
  while ((dev = sd_device_enumerator_get_device_next(e)) != NULL) i++;

  sd_device_enumerator_unref(e);
  return i;
}

static NtList* nt_systemd_device_enum_query(NtDeviceEnum* device_enum, NtDeviceQuery query) {
  NtSystemdDeviceEnum* self = NT_SYSTEMD_DEVICE_ENUM((NtTypeInstance*)device_enum);
  assert(self != NULL);

  sd_device_enumerator* e = create_enumerator(self, query);
  
  sd_device* dev = NULL;
  NtList* list = NULL;

  while ((dev = sd_device_enumerator_get_device_next(e)) != NULL) {
    list = nt_list_append(list, NT_VALUE_POINTER(nt_systemd_device_new(dev)));
  }

  sd_device_enumerator_unref(e);
  return list;
}

static void nt_systemd_device_enum_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtDeviceEnum* device_enum = NT_DEVICE_ENUM(instance);
  assert(device_enum != NULL);

  NtSystemdDeviceEnum* self = NT_SYSTEMD_DEVICE_ENUM(instance);
  assert(self != NULL);

  device_enum->count = nt_systemd_device_enum_count;
  device_enum->query = nt_systemd_device_enum_query;

  self->priv = malloc(sizeof (NtSystemdDeviceEnumPrivate));
  assert(self->priv != NULL);

  sd_device_monitor_new(&self->priv->monitor);
}

static void nt_systemd_device_enum_destroy(NtTypeInstance* instance) {
  NtSystemdDeviceEnum* self = NT_SYSTEMD_DEVICE_ENUM(instance);
  assert(self != NULL);

  sd_device_monitor_unref(self->priv->monitor);
  free(self->priv);
}

NtDeviceEnum* nt_systemd_device_enum_new() {
  return NT_DEVICE_ENUM(nt_type_instance_new(NT_TYPE_SYSTEMD_DEVICE_ENUM, NULL));
}
