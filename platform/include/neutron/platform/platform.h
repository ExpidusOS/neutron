#pragma once

#include <neutron/elemental.h>
#include <neutron/platform/device/enum.h>

struct _NtPlatform;

/**
 * NtPlatformOS:
 *
 * Enum of different operating systems
 */
typedef enum _NtPlatformOS {
  NT_PLATFORM_OS_UNKNOWN = 0,
  NT_PLATFORM_OS_LINUX,
  NT_PLATFORM_OS_DARWIN,
  NT_PLATFORM_OS_ANDROID,
  NT_PLATFORM_OS_WINDOWS
} NtPlatformOS;

/**
 * NtPlatformArch:
 *
 * Enum of different CPU architectures
 */
typedef enum _NtPlatformArch {
  NT_PLATFORM_ARCH_UNKNOWN = 0,
  NT_PLATFORM_ARCH_AARCH64,
  NT_PLATFORM_ARCH_ARM,
  NT_PLATFORM_ARCH_RISCV32,
  NT_PLATFORM_ARCH_RISCV64,
  NT_PLATFORM_ARCH_X86,
  NT_PLATFORM_ARCH_X86_64
} NtPlatformArch;

typedef struct _NtPlatform {
  NtTypeInstance instance;
  struct _NtPlatformPrivate* priv;

  NtPlatformOS (*get_os)(struct _NtPlatform* self);
  NtPlatformArch (*get_arch)(struct _NtPlatform* self);
  NtDeviceEnum* (*get_device_enum)(struct _NtPlatform* self);
} NtPlatform;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

#define NT_TYPE_PLATFORM nt_platform_get_type()
NT_DECLARE_TYPE(NT, PLATFORM, NtPlatform, nt_platform);

/**
 * nt_platform_get_global:
 *
 * Get the global platform instance
 */
NtPlatform* nt_platform_get_global();

/**
 * nt_platform_get_os:
 *
 * Get the operating system the platform is running on
 */
NtPlatformOS nt_platform_get_os(NtPlatform* self);

/**
 * nt_platform_get_arch:
 *
 * Get the CPU architecture the platform is running on
 */
NtPlatformArch nt_platform_get_arch(NtPlatform* self);

/**
 * nt_platform_get_device_enum:
 *
 * Gets the device enumerator
 */
NtDeviceEnum* nt_platform_get_device_enum(NtPlatform* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
