#include <neutron/inputcore/keyboard.h>

NT_DEFINE_TYPE(NT, KEYBOARD_INPUT, NtKeyboardInput, nt_keyboard_input, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_INPUT_DEVICE, NT_TYPE_NONE);

static void nt_keyboard_input_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_keyboard_input_destroy(NtTypeInstance* instance) {}
