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
 * @list_packages: Method for listing packages
 * @install: Method for installing a package
 * @uninstall: Method for uninstalling a package
 *
 * Type for looking up and managing packages
 */
typedef struct _NtPackageManager {
  NtTypeInstance instance;

  NtList* (*list)(struct _NtPackageManager* self, NtPackageLocation loc, NtBacktrace* bt, NtError** error);
  bool (*install)(struct _NtPackageManager* self, NtPackage* pkg, NtPackageLocation loc, NtBacktrace* bt, NtError** error);
  bool (*uninstall)(struct _NtPackageManager* self, NtPackage* pkg, NtBacktrace* bt, NtError** error);
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

/**
 * nt_package_manager_list:
 * @self: Instance of the package manager
 * @loc: Location to browse
 * @bt: Backtrace
 * @error: Pointer for storing the error
 *
 * Lists packages which are on the system.
 *
 * Returns: %NtList containing %NtPackage
 */
NtList* nt_package_manager_list(NtPackageManager* self, NtPackageLocation loc, NtBacktrace* bt, NtError** error);

/**
 * nt_package_manager_install:
 * @self: Instance of the package manager
 * @path: Path to the compressed package
 * @loc: Location to install the package
 * @bt: Backtrace
 * @error: Pointer for storing the error
 *
 * Installs the package into a specific package location on the system.
 *
 * Returns: %NULL if failed, an instance of %NtPackage for when it succeeded.
 */
NtPackage* nt_package_manager_install(NtPackageManager* self, const char* path, NtPackageLocation loc, NtBacktrace* bt, NtError** error);

/**
 * nt_package_manager_uninstall:
 * @self: Instance of the package manager
 * @pkg: The package to uninstall
 * @bt: Backtrace
 * @error: Pointer for storing the error
 *
 * Uninstalls @pkg
 *
 * Returns: %true is success, %false if failed and @error will be set.
 */
bool nt_package_manager_uninstall(NtPackageManager* self, NtPackage* pkg, NtBacktrace* bt, NtError** error);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
