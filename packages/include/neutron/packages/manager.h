#pragma once

#include <neutron/elemental.h>
#include <neutron/packages/package.h>

NT_BEGIN_DECLS

/**
 * SECTION: manager
 * @title: Package Manager
 * @short_description: Type for looking up and managing packages
 */

/**
 * NtPackageManager:
 * @instance: The %NtTypeInstance associated
 * @priv: Private data
 *
 * Type for looking up and managing packages
 */
typedef struct _NtPackageManager {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtPackageManagerPrivate* priv;
} NtPackageManager;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_PACKAGE_MANAGER:
 *
 * The %NtType ID of %NtPackageManager
 */
#define NT_TYPE_PACKAGE_MANAGER nt_package_manager_get_type()
NT_DECLARE_TYPE(NT, PACKAGE_MANAGER, NtPackageManager, nt_package_manager);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
