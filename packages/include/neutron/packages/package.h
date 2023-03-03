#pragma once

#include <neutron/elemental.h>

NT_BEGIN_DECLS

/**
 * SECTION: package
 * @title: Package
 * @short_description: Type for a package
 */

/**
 * NtPackageLocation:
 * @NT_PACKAGE_LOC_UNKNOWN: An unknown location
 * @NT_PACKAGE_LOC_SYSTEM: System-wide installed packages
 * @NT_PACKAGE_LOC_USER: User installed packages
 *
 * Enum for package locations
 */
typedef enum _NtPackageLocation {
  NT_PACKAGE_LOC_UNKNOWN = 0,
  NT_PACKAGE_LOC_SYSTEM,
  NT_PACKAGE_LOC_USER
} NtPackageLocation;

/**
 * NtPackageManager:
 * @instance: The %NtTypeInstance associated
 * @priv: Private data
 *
 * Type for a package
 */
typedef struct _NtPackage {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtPackagePrivate* priv;
} NtPackage;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_PACKAGE:
 *
 * The %NtType ID of %NtPackage
 */
#define NT_TYPE_PACKAGE nt_package_get_type()
NT_DECLARE_TYPE(NT, PACKAGE, NtPackage, nt_package);

/**
 * nt_package_new:
 * @path: The absolute path to the directory which contains the package
 *
 * Creates a new instance of the package type for the package which matches the path.
 *
 * Returns: A package instance
 */
NtPackage* nt_package_new(const char* path);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
