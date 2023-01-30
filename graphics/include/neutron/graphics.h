#pragma once

#include <neutron/graphics/build.h>
#include <neutron/graphics/renderer.h>
#include <neutron/graphics/scene.h>
#include <neutron/graphics/scene-layer.h>

#ifdef NT_GRAPHICS_HAS_EGL
#include <neutron/graphics/renderer/egl.h>
#endif

#ifdef NT_GRAPHICS_HAS_PIXMAN
#include <neutron/graphics/renderer/pixman.h>
#endif
