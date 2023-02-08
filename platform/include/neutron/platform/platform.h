#pragma once

#include <neutron/elemental.h>
#include <neutron/platform/device-enum.h>

struct _NtPlatform;
struct _NtProcess;

/**
 * SECTION: platform
 * @title: Platform
 * @short_description: Generic platform API
 */

/**
 * NtPlatformOS:
 * @NT_PLATFORM_OS_UNKNOWN: OS could not be determined
 * @NT_PLATFORM_OS_LINUX: Linux
 * @NT_PLATFORM_OS_DARWIN: Apple's Darwin based operating systems
 * @NT_PLATFORM_OS_ANDROID: Android
 * @NT_PLATFORM_OS_WINDOWS: Microsoft Windows
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
 * @NT_PLATFORM_ARCH_UNKNOWN: CPU architecture could not be determined
 * @NT_PLATFORM_ARCH_AARCH64: 64-bit ARM
 * @NT_PLATFORM_ARCH_ARM: 32-bit ARM
 * @NT_PLATFORM_ARCH_RISCV32: 32-bit RISC-V
 * @NT_PLATFORM_ARCH_RISCV64: 64-bit RISC-V
 * @NT_PLATFORM_ARCH_X86: 32-bit x86 (i386, i486, i686, etc.)
 * @NT_PLATFORM_ARCH_X86_64: 64-bit x86 (amd64)
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

/**
 * NtPlatform:
 * @instance: The %NtTypeInstance associated with this
 * @get_os: Method for retrieving the %NtPlatformOS
 * @get_arch: Method for retrieving the %NtPlatformArch
 * @get_device_enum: Method for retrieving the %NtDeviceEnum instance
 * @get_current_process: Method for retrieving the current process
 * @priv: Private data
 *
 * An %NtTypeInstance used for platform specific API methods
 */
typedef struct _NtPlatform {
  NtTypeInstance instance;

  NtPlatformOS (*get_os)(struct _NtPlatform* self);
  NtPlatformArch (*get_arch)(struct _NtPlatform* self);
  NtDeviceEnum* (*get_device_enum)(struct _NtPlatform* self);
  struct _NtProcess* (*get_current_process)(struct _NtPlatform* self);

  /*< private >*/
  struct _NtPlatformPrivate* priv;
} NtPlatform;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_PLATFORM:
 *
 * The %NtType ID of %NtPlatform
 */
#define NT_TYPE_PLATFORM nt_platform_get_type()
NT_DECLARE_TYPE(NT, PLATFORM, NtPlatform, nt_platform);

/**
 * nt_platform_get_global:
 *
 * Gets the global platform instance
 *
 * Returns: An instance of %NtPlatform
 */
NtPlatform* nt_platform_get_global();

/**
 * nt_platform_get_os:
 * @self: The %NtPlatform instance to use
 *
 * Get the operating system the platform is running on
 * Returns: The operating system the platform is running on
 */
NtPlatformOS nt_platform_get_os(NtPlatform* self);

/**
 * nt_platform_get_arch:
 * @self: The %NtPlatform instance to use
 *
 * Get the CPU architecture the platform is running on
 * Returns: The CPU architecture the platform is running on
 */
NtPlatformArch nt_platform_get_arch(NtPlatform* self);

/**
 * nt_platform_get_device_enum:
 * @self: The %NtPlatform instance to use
 *
 * Gets the device enumerator
 * Returns: The device enumerator for the platform
 */
NtDeviceEnum* nt_platform_get_device_enum(NtPlatform* self);

/**
 * nt_platform_get_current_process:
 * @self: The %NtPlatform instance to use
 *
 * Gets the currently running process
 *
 * Returns: Instance of the currently running %NtProcess
 */
struct _NtProcess* nt_platform_get_current_process(NtPlatform* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
