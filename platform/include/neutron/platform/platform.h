#pragma once

#include <neutron/elemental.h>

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
 * NtPlatformImplementation:
 *
 * Platform specific method calls
 */
typedef struct _NtPlatformImplementation {
  NtPlatformOS (*get_os)(struct _NtPlatform* platform);
} NtPlatformImplementation;

typedef struct _NtPlatform {
  NtTypeInstance instance;
  struct _NtPlatformPrivate* priv;
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

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
