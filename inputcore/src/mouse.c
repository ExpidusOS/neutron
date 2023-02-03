#include <neutron/inputcore/mouse.h>

NT_DEFINE_TYPE(NT, MOUSE_INPUT, NtMouseInput, nt_mouse_input, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_INPUT_DEVICE, NT_TYPE_NONE);

static void nt_mouse_input_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_mouse_input_destroy(NtTypeInstance* instance) {}
