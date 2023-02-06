#pragma once

#include <neutron/displaykit/compositors/wlroots-compositor.h>
#include <wlr/backend.h>
#include <wlr/render/allocator.h>
#include <wlr/render/pixman.h>
#include <wlr/render/wlr_renderer.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_data_device.h>
#include <wlr/types/wlr_output_layout.h>
#include <wlr/types/wlr_presentation_time.h>
#include <wlr/types/wlr_seat.h>
#include <wlr/types/wlr_xcursor_manager.h>
#include <wlr/types/wlr_xdg_shell.h>
#include <wayland-server-core.h>

typedef struct _NtWlrootsCompositorPrivate {
  struct wl_display* display;
  struct wl_event_loop* event_loop;
  struct wlr_backend* backend;
  struct wlr_renderer* wl_renderer;
  struct wlr_allocator* allocator;
  struct wlr_output_layout* output_layout;
  struct wlr_xdg_shell* xdg_shell;
  struct wlr_presentation* presentation;
  struct wlr_seat* seat;
  struct wlr_xcursor_manager* xcursor_mngr;
} NtWlrootsCompositorPrivate;
