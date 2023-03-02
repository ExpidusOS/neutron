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
} NtPackageMetadata;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_PACKAGE_METADATA:
 *
 * The %NtType ID of %NtPackageMetadata
 */
#define NT_TYPE_PACKAGE_METADATA nt_package_metadata_get_type()
NT_DECLARE_TYPE(NT, PACKAGE_METADATA, NtPackageMetadata, nt_package_metadata);

/**
 * nt_package_metadata_new:
 * @path: Path to the XML file
 *
 * Opens @path and reads the AppStream data from it.
 *
 * Returns: A new package metadata instance
 */
NtPackageMetadata* nt_package_metadata_new(const char* path);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
