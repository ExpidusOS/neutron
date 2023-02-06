#include <neutron/displaykit/context.h>
#include <assert.h>

NT_DEFINE_TYPE(NT, DISPLAY_CONTEXT, NtDisplayContext, nt_display_context, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_display_context_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtDisplayContext* self = NT_DISPLAY_CONTEXT(instance);
  assert(self != NULL);

  self->output_new = nt_signal_new();
  self->view_new = nt_signal_new();
}

static void nt_display_context_destroy(NtTypeInstance* instance) {
  NtDisplayContext* self = NT_DISPLAY_CONTEXT(instance);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->output_new);
  nt_type_instance_unref((NtTypeInstance*)self->view_new);
}
