#pragma once

#include <neutron/elemental.h>

NT_BEGIN_DECLS

/**
 * SECTION: metadata
 * @title: Metadata
 * @short_description: Type for reading package metadata
 */

/**
 * NtPackageMetadata:
 * @instance: The %NtTypeInstance associated
 * @priv: Private data
 *
 * Type for a package
 */
typedef struct _NtPackageMetadata {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtPackageMetadataPrivate* priv;
} NtPackage;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
