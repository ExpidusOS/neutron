#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#if defined(__GNUC__) || defined(__clang__)
#define NT_PUBLIC __attribute__((visibility("default")))
#define NT_PRIVATE __attribute__((visibility("default")))
#elif defined(_WIN32) || defined(__CYGWIN__)
#define NT_PUBLIC __declspec(dllimport)
#define NT_PRIVATE
#else
#warn "Unsupport compiler"
#define NT_PUBLIC
#define NT_PRIVATE
#endif

#ifdef __cplusplus
#define NT_BEGIN_DECLS extern "C" {
#define NT_END_DECLS }
#else
#define NT_BEGIN_DECLS
#define NT_END_DECLS
#endif

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
  void (*construct)(struct _NtTypeInstance* instance);

  /**
   * Method to run when this type is deallocated by nt_type_instance_destroy
   */
  void (*destroy)(struct _NtTypeInstance* instance);
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
  NtType type;

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

#define NT_TYPEDEF_CONSTRUCT(func_name) info.construct = func_name ## _construct;
#define NT_TYPEDEF_DESTROY(func_name) info.destroy = func_name ## _destroy;

#define NT_DEFINE_TYPE_WITH_CODE(ns, name, struct_name, func_name, flgs, code) \
  const size_t ns ## _ ## name ## _SIZE = sizeof (struct_name) - sizeof (NtTypeInstance); \
  struct_name * ns ## _ ## name(NtTypeInstance* instance) { \
    return (struct_name *)nt_type_instance_get_data(instance, func_name ## _get_type()); \
  } \
  const bool ns ## _IS_ ## name(struct_name* self) { \
    return nt_type_isof(func_name ## _get_type(), ((NtTypeInstance*)self)->type); \
  } \
  NtType func_name ## _get_type() { \
    static NtType id = NT_TYPE_NONE; \
    if (id == NT_TYPE_NONE) { \
      static NtTypeInfo info = {}; \
      info.flags = flgs; \
      info.size = sizeof (struct_name) - sizeof (NtTypeInstance); \
      code \
      id = nt_type_register(&info); \
    } \
    return id; \
  }

#define NT_DEFINE_TYPE(ns, name, struct_name, func_name, flags) \
  static void func_name ## _construct(NtTypeInstance* instance, void* data); \
  static void func_name ## _destroy(NtTypeInstance* instance, void* data); \
  NT_DEFINE_TYPE_WITH_CODE(ns, name, struct_name, func_name, flags, \
    NT_TYPEDEF_CONSTRUCT(func_name) \
    NT_TYPEDEF_DESTROY(func_name))

#define NT_DECLARE_TYPE(ns, name, struct_name, func_name) \
  extern const size_t ns ## _ ## name ## _SIZE; \
  struct_name * ns ## _ ## name(NtTypeInstance* instance); \
  const bool ns ## _IS_ ## name(struct_name* self); \
  NtType func_name ## _get_type();

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_type_register:
 *
 * Register a new type
 */
NtType nt_type_register(NtTypeInfo* info);

/**
 * nt_type_register:
 *
 * Unregisters a type
 */
void nt_type_unregister(NtTypeInfo* info);

/**
 * nt_type_isof:
 *
 * Returns a boolean of whether or not type extends "base"
 */
bool nt_type_isof(NtType type, NtType base);

/**
 * nt_type_info_from_type:
 *
 * Get type information from a type ID
 */
const NtTypeInfo* nt_type_info_from_type(NtType type);

/**
 * nt_type_info_get_total_size:
 *
 * Returns the total size of all elements except the size of NtTypeInstance
 */
const size_t nt_type_info_get_total_size(NtTypeInfo* info);

/**
 * nt_type_instance_new:
 *
 * Constructs a new type instance.
 *
 * The resulting pointer will be (sizeof (NtTypeInstance) + total size)
 * where total size is determined by all parent NtTypeInfo size elements.
 */
NtTypeInstance* nt_type_instance_new(NtType type);

/**
 * nt_type_instance_get_data:
 *
 * Gets the instance of type inside of the parent instance
 */
NtTypeInstance* nt_type_instance_get_data(NtTypeInstance* instance, NtType type);

/**
 * nt_type_instance_ref:
 *
 * Increases the ref_count of the type instance
 */
NtTypeInstance* nt_type_instance_ref(NtTypeInstance* instance);

/**
 * nt_type_instance_destroy:
 *
 * Destroys a type instance if ref_count is 0. If ref_count is
 * greater than 0, then it is deincremented.
 */
void nt_type_instance_destroy(NtTypeInstance* instance);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
