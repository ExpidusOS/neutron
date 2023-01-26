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

#define NT_TYPE_NONE 0

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
  NT_TYPE_FLAG_DYNAMIC = (0 << 0),

  /**
   * Defines a type which cannot be referenced
   */
  NT_TYPE_FLAG_NOREF = (1 << 1)
} NtTypeFlags;

struct _NtTypeInstance;

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
   * An array which ends with "NT_TYPE_NONE" to determine all parent types
   */
  NtType* extends;

  /**
   * Size of the allocated data
   */
  size_t size;

  /**
   * Method to run when this type is allocated by nt_type_instance_new
   */
  void (*construct)(struct _NtTypeInstance* instance, void* data);

  /**
   * Method to run when this type is deallocated by nt_type_instance_destroy
   */
  void (*destroy)(struct _NtTypeInstance* instance, void* data);
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

  /**
   * Pointer to the start of the instance data
   */
  void* data;

  /**
   * The size of the data which does not include
   * the size of NtTypeInstance
   */
  size_t data_size;

  /**
   * Number of references this instance has
   */
  size_t ref_count;
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

/**
 * nt_type_info_get_total_size:
 *
 * Returns the total size of all elements except the size of NtTypeInstance
 */
NT_EXPORT const size_t nt_type_info_get_total_size(NtTypeInfo* info);

/**
 * nt_type_instance_new:
 *
 * Constructs a new type instance.
 *
 * The resulting pointer will be (sizeof (NtTypeInstance) + total size)
 * where total size is determined by all parent NtTypeInfo size elements.
 */
NT_EXPORT NtTypeInstance* nt_type_instance_new(NtType type);

/**
 * nt_type_instance_ref:
 *
 * Increases the ref_count of the type instance
 */
NT_EXPORT NtTypeInstance* nt_type_instance_ref(NtTypeInstance* instance);

/**
 * nt_type_instance_destroy:
 *
 * Destroys a type instance if ref_count is 0. If ref_count is
 * greater than 0, then it is deincremented.
 */
NT_EXPORT void nt_type_instance_destroy(NtTypeInstance* instance);
