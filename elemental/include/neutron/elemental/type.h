#pragma once

#include <stdint.h>
#include <stdlib.h>

#define NT_EXPORT __attribute__ ((visibility("default")))

/**
 * NtType:
 *
 * ID of a registered type
 */
typedef uint32_t NtType;

/**
 * NtTypeFlags:
 *
 * Enum of flags for registering types
 */
typedef enum _NtTypeFlags {
  /**
   * Defines a static type, this means it cannot be derived.
   */
  NT_TYPE_FLAG_STATIC = (1 << 0),

  /**
   * Defines a dynamic type, this means the it can be derived.
   */
  NT_TYPE_FLAG_DYNAMIC = (0 << 1)
} NtTypeFlags;

/**
 * NtTypeExtensionInfo:
 *
 * Describes what types a type is extending or implementing
 */
typedef struct _NtTypeExtensionInfo {
  /**
   * Type ID to extend
   */
  NtType id;

  /**
   * Offset to the location of the instance info
   */
  size_t offset;
} NtTypeExtensionInfo;

/**
 * NtTypeClassInfo:
 *
 * Describes how a class must be defined
 */
typedef struct _NtTypeClassInfo {
  /**
   * Name of the class which must be PascalCase
   */
  const char* name;

  /**
   * Size of the allocated class
   */
  size_t size;
} NtTypeClassInfo;

/**
 * NtTypeInfo:
 *
 * Describes how a type should be defined
 */
typedef struct _NtTypeInfo {
  /**
   * ID of the registered type
   */
  NtType id;

  /**
   * Flags describing how the type can work
   */
  NtTypeFlags flags;

  /**
   * Class registration info
   */
  NtTypeClassInfo class_info;
} NtTypeInfo;

/**
 * NtTypeInstance:
 *
 * Instance of a type
 */
typedef struct _NtTypeInstance {
  /**
   * Type information
   */
  const NtTypeInfo* info;
} NtTypeInstance;

/**
 * nt_type_register:
 *
 * Register a new type
 */
NT_EXPORT NtType nt_type_register(NtTypeInfo* info);

/**
 * nt_type_register:
 *
 * Unregisters a type
 */
NT_EXPORT void nt_type_unregister(NtTypeInfo* info);

/**
 * nt_type_info_from_type:
 *
 * Get type information from a type ID
 */
NT_EXPORT const NtTypeInfo* nt_type_info_from_type(NtType type);
