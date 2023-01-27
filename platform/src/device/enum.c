#include <neutron/platform/device/enum.h>
#include <assert.h>

NT_DEFINE_TYPE(NT, DEVICE_ENUM, NtDeviceEnum, nt_device_enum, NT_TYPE_FLAG_STATIC);

static void nt_device_enum_construct(NtTypeInstance* instance) {}
static void nt_device_enum_destroy(NtTypeInstance* instance) {}

size_t nt_device_enum_get_device_count(NtDeviceEnum* self) {
  assert(NT_IS_DEVICE_ENUM(self));
  assert(self->get_device_count != NULL);
  return self->get_device_count(self);
}
