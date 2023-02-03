#include <neutron/inputcore/touch.h>

NT_DEFINE_TYPE(NT, TOUCH_INPUT, NtTouchInput, nt_touch_input, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_INPUT_DEVICE, NT_TYPE_NONE);

static void nt_touch_input_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_touch_input_destroy(NtTypeInstance* instance) {}
