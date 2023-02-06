#include <neutron/displaykit/view.h>
#include <assert.h>

NT_DEFINE_TYPE(NT, DISPLAY_VIEW, NtDisplayView, nt_display_view, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_display_view_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtDisplayView* self = NT_DISPLAY_VIEW(instance);
  assert(self != NULL);

  self->destroy = nt_signal_new();
}

static void nt_display_view_destroy(NtTypeInstance* instance) {
  NtDisplayView* self = NT_DISPLAY_VIEW(instance);
  assert(self != NULL);

  nt_type_instance_unref((NtTypeInstance*)self->destroy);
}
