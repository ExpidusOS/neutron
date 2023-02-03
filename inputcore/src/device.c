#include <neutron/inputcore/device.h>

NT_DEFINE_TYPE(NT, INPUT_DEVICE, NtInputDevice, nt_input_device, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_input_device_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_input_device_destroy(NtTypeInstance* instance) {}
