#include <neutron/platform/device-enum.h>
#include <assert.h>

NT_DEFINE_TYPE(NT, DEVICE_ENUM, NtDeviceEnum, nt_device_enum, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_device_enum_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtDeviceEnum* self = NT_DEVICE_ENUM(instance);
  assert(self != NULL);

  self->added = nt_signal_new();
  self->removed = nt_signal_new();
}

static void nt_device_enum_destroy(NtTypeInstance* instance) {
  NtDeviceEnum* self = NT_DEVICE_ENUM(instance);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->added);
  nt_type_instance_unref((NtTypeInstance*)self->removed);
}

size_t nt_device_enum_get_device_count(NtDeviceEnum* self) {
  assert(NT_IS_DEVICE_ENUM(self));
  assert(self->get_device_count != NULL);
  return self->get_device_count(self);
}
