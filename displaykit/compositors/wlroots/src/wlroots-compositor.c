#include <neutron/displaykit/compositors/wlroots-compositor.h>
#include <neutron/graphics.h>
#include <assert.h>
#include <stdlib.h>
#include "wlroots-compositor-priv.h"

NT_DEFINE_TYPE(NT, WLROOTS_COMPOSITOR, NtWlrootsCompositor, nt_wlroots_compositor, NT_TYPE_FLAG_STATIC, NT_TYPE_DISPLAY_COMPOSITOR);

static void nt_wlroots_compositor_rendered_init(NtWlrootsCompositor* self, NtError** error, NtBacktrace* backtrace) {
  nt_backtrace_push(backtrace, nt_wlroots_compositor_rendered_init);

  self->priv->seat = wlr_seat_create(self->priv->display, "seat0");

  self->priv->xcursor_mngr = wlr_xcursor_manager_create(NULL, 24);
  wlr_xcursor_manager_load(self->priv->xcursor_mngr, 1);

  self->priv->allocator = wlr_allocator_autocreate(self->priv->backend, self->priv->wl_renderer);
  self->priv->compositor = wlr_compositor_create(self->priv->display, self->priv->wl_renderer);

  self->priv->output_layout = wlr_output_layout_create();
  self->priv->xdg_shell = wlr_xdg_shell_create(self->priv->display);

  if ((self->priv->socket = wl_display_add_socket_auto(self->priv->display)) == NULL) {
    *error = nt_error_new("Failed to create a socket", backtrace);
    nt_backtrace_pop(backtrace);
    return;
  }

  self->priv->presentation = wlr_presentation_create(self->priv->display, self->priv->backend);

  if (!wlr_backend_start(self->priv->backend)) {
    *error = nt_error_new("Failed to start the wlroots backend", backtrace);
    nt_backtrace_pop(backtrace);
    return;
  }

  nt_backtrace_pop(backtrace);
}

static void nt_wlroots_compositor_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtWlrootsCompositor* self = NT_WLROOTS_COMPOSITOR(instance);
  assert(self != NULL);

  self->priv = malloc(sizeof (NtWlrootsCompositorPrivate));
  assert(self != NULL);

  NtValue backtrace_value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtWlrootsCompositor, backtrace), NT_VALUE_INSTANCE(NULL));
  assert(backtrace_value.type == NT_VALUE_TYPE_INSTANCE);

  NtBacktrace* backtrace = NT_BACKTRACE(backtrace_value.data.instance);
  assert(backtrace != NULL);

  NtValue error_value = nt_type_argument_get(arguments, NT_TYPE_ARGUMENT_KEY(NtWlrootsCompositor, error), NT_VALUE_POINTER(NULL));
  assert(error_value.type == NT_VALUE_TYPE_POINTER);

  NtError** error = (NtError**)error_value.data.pointer;
  assert(error != NULL);

  nt_backtrace_push(backtrace, nt_wlroots_compositor_construct);

  self->priv->display = wl_display_create();
  self->priv->event_loop = wl_display_get_event_loop(self->priv->display);
  self->priv->backend = wlr_backend_autocreate(self->priv->display);

  int drm_fd = -1;
  if (drm_fd < 0) {
    if ((drm_fd = wlr_backend_get_drm_fd(self->priv->backend)) < 0) {
      *error = nt_error_new("Failed to open a DRM device", backtrace);
      nt_backtrace_pop(backtrace);
      return;
    }
  }

#ifdef NT_GRAPHICS_HAS_PIXMAN
  if ((self->priv->wl_renderer = wlr_pixman_renderer_create()) == NULL) {
    *error = nt_error_new("Failed to create a Pixman renderer", backtrace);
    nt_backtrace_pop(backtrace);
    return;
  }

  self->priv->renderer = nt_pixman_renderer_new(NULL); // TODO: figure out how to properly send over the pixman image
  nt_wlroots_compositor_rendered_init(self, error, backtrace);
#else
  *error = nt_error_new("No renderers are available for wlroots", backtrace);
#endif

  nt_backtrace_pop(backtrace);
}

static void nt_wlroots_compositor_destroy(NtTypeInstance* instance) {
  NtWlrootsCompositor* self = NT_WLROOTS_COMPOSITOR(instance);
  assert(self != NULL);

  free(self->priv);
}

NtDisplayCompositor* nt_wlroots_compositor_new(NtBacktrace* backtrace, NtError** error) {
  return NT_DISPLAY_COMPOSITOR(nt_type_instance_new(NT_TYPE_WLROOTS_COMPOSITOR, (NtTypeArgument[]){
    { NT_TYPE_ARGUMENT_KEY(NtWlrootsCompositor, backtrace), NT_VALUE_INSTANCE((NtTypeInstance*)backtrace) },
    { NT_TYPE_ARGUMENT_KEY(NtWlrootsCompositor, error), NT_VALUE_POINTER(error) },
    { NULL }
  }));
}
