#pragma once

#include <neutron/elemental.h>
#include <neutron/platform/platform.h>

/**
 * SECTION: linux-platform
 * @title: Linux Platform
 * @short_description: A platform implementation for Linux
 * @see_also: #NtPlatform
 */

/**
 * NtLinuxPlatform:
 * @instance: The %NtTypeInstance associated with this
 *
 * A platform implementation for Linux
 */
typedef struct _NtLinuxPlatform {
  NtTypeInstance instance;
} NtLinuxPlatform;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_LINUX_PLATFORM:
 *
 * The %NtType for %NtLinuxPlatform
 */
#define NT_TYPE_LINUX_PLATFORM nt_linux_platform_get_type()
NT_DECLARE_TYPE(NT, LINUX_PLATFORM, NtLinuxPlatform, nt_linux_platform);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
