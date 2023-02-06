#include <neutron/displaykit/output.h>
#include <assert.h>

NT_DEFINE_TYPE(NT, DISPLAY_OUTPUT, NtDisplayOutput, nt_display_output, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_display_output_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtDisplayOutput* self = NT_DISPLAY_OUTPUT(instance);
  assert(self != NULL);

  self->destroy = nt_signal_new();
}

static void nt_display_output_destroy(NtTypeInstance* instance) {
  NtDisplayOutput* self = NT_DISPLAY_OUTPUT(instance);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->destroy);
}
