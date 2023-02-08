#include <neutron/platform/device.h>
#include <assert.h>
#include <stdlib.h>

NT_DEFINE_TYPE(NT, DEVICE, NtDevice, nt_device, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_device_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_device_destroy(NtTypeInstance* instance) {}

NtDeviceQuery nt_device_get_query(NtDevice* self) {
  assert(NT_IS_DEVICE(self));
  assert(self->get_query != NULL);
  return self->get_query(self);
}
