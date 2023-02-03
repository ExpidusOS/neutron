#include <neutron/platform/device.h>

NT_DEFINE_TYPE(NT, DEVICE, NtDevice, nt_device, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_device_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_device_destroy(NtTypeInstance* instance) {}
