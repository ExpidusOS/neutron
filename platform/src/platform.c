#include <neutron/platform/platform.h>
#include <assert.h>
#include <stdlib.h>
#include "platform-priv.h"

NT_DEFINE_TYPE(NT, PLATFORM, NtPlatform, nt_platform, NT_TYPE_FLAG_STATIC);

static void nt_platform_construct(NtTypeInstance* inst, NtTypeArgument* arguments) {
  NtPlatform* self = NT_PLATFORM(inst);

  self->priv = malloc(sizeof (NtPlatformPrivate));
  assert(self->priv != NULL);
}

static void nt_platform_destroy(NtTypeInstance* inst) {
  NtPlatform* self = NT_PLATFORM(inst);

  if (self->priv->device_enum != NULL) {
    nt_type_instance_destroy((NtTypeInstance*)self->priv->device_enum);
    self->priv->device_enum = NULL;
  }

  free(self->priv);
  self->priv = NULL;
}

NtPlatform* nt_platform_get_global() {
  static NtPlatform* global;
  if (global == NULL) {
    global = NT_PLATFORM(nt_type_instance_new(NT_TYPE_PLATFORM, NULL));
    assert(global != NULL);
  }
  return NT_PLATFORM(nt_type_instance_ref((NtTypeInstance*)global));
}

NtPlatformOS nt_platform_get_os(NtPlatform* self) {
  assert(NT_IS_PLATFORM(self));
  if (self->get_os != NULL) return self->get_os(self);

#if defined(WINDOWS) || defined(CYGWIN)
  return NT_PLATFORM_OS_WINDOWS;
#elif defined(LINUX)
  return NT_PLATFORM_OS_LINUX;
#elif defined(ANDROID)
  return NT_PLATFORM_OS_ANDROID;
#elif defined(DARWIN)
  return NT_PLATFORM_OS_DARWIN;
#else
  return NT_PLATFORM_OS_UNKNOWN;
#endif
}

NtPlatformArch nt_platform_get_arch(NtPlatform* self) {
  assert(NT_IS_PLATFORM(self));
  if (self->get_arch != NULL) return self->get_arch(self);

#if defined(AARCH64)
  return NT_PLATFORM_ARCH_AARCH64;
#elif defined(ARM)
  return NT_PLATFORM_ARCH_ARM;
#elif defined(RISCV32)
  return NT_PLATFORM_ARCH_RISCV32;
#elif defined(RISCV64)
  return NT_PLATFORM_ARCH_RISCV64;
#elif defined(X86)
  return NT_PLATFORM_ARCH_X86;
#elif defined(X86_64)
  return NT_PLATFORM_ARCH_X86_64;
#else
  return NT_PLATFORM_ARCH_UNKNOWN;
#endif
}

NtDeviceEnum* nt_platform_get_device_enum(NtPlatform* self) {
  assert(NT_IS_PLATFORM(self));

  if (self->priv->device_enum == NULL) {
    assert(self->get_device_enum != NULL);

    self->priv->device_enum = self->get_device_enum(self);
    assert(self->priv->device_enum != NULL);
  }

  return NT_DEVICE_ENUM(nt_type_instance_ref((NtTypeInstance*)self->priv->device_enum));
}
