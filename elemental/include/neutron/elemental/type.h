#pragma once

#include <neutron/elemental/argument.h>
#include <neutron/elemental/common.h>
#include <neutron/elemental/value.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * SECTION: type
 * @title: Type
 * @short_description: Type definition and declaration
 */

/**
 * NtType:
 *
 * ID of a registered type
 */
typedef uint32_t NtType;

/**
 * NT_TYPE_NONE:
 *
 * An %NtType which describes nothing
 */
#define NT_TYPE_NONE 0

/**
 * NtTypeFlags:
 * @NT_TYPE_FLAG_STATIC: Defines a static type, this means it cannot be derived.
 * @NT_TYPE_FLAG_DYNAMIC: Defines a dynamic type, this means the it can be derived.
 * @NT_TYPE_FLAG_NOREF: Defines a type which cannot be referenced
 *
 * Enum of flags for registering types
 */
typedef enum _NtTypeFlags {
  NT_TYPE_FLAG_STATIC = (1 << 0),
  NT_TYPE_FLAG_DYNAMIC = (0 << 0),
  NT_TYPE_FLAG_NOREF = (1 << 1)
} NtTypeFlags;

struct _NtTypeInstance;

/**
 * NtTypeInfo:
 * @id: The ID of the type
 * @flags: Flags describing how the type can work
 * @extends: An array which ends with "NT_TYPE_NONE" to determine all parent types
 * @size: Size of the allocated data
 * @construct: Method to run when this type is allocated by %nt_type_instance_new
 * @destroy: Method to run when this type is deallocated by %nt_type_instance_unref
 *
 * Describes how a type should be defined
 */
typedef struct _NtTypeInfo {
  NtType id;
  NtTypeFlags flags;
  NtType* extends;
  size_t size;
  void (*construct)(struct _NtTypeInstance* instance, NtTypeArgument* arguments);
  void (*destroy)(struct _NtTypeInstance* instance);
} NtTypeInfo;

/**
 * NtTypeInstance:
 * @type: The type the instance was allocated for
 * @data: Pointer to the start of the instance data
 * @data_size: The total size of %NtTypeInstance
 * @ref_count: Number of references this instance has
 *
 * Instance of a type
 */
typedef struct _NtTypeInstance {
  NtType type;
  void* data;
  size_t data_size;
  size_t ref_count;
} NtTypeInstance;

/**
 * NT_TYPEDEF_CONSTRUCT:
 * @func_name: The snake_case of the method name prefix for a type
 *
 * A code value to pass to %NT_DEFINE_TYPE_WITH_CODE which is used to set the construct method.
 */
#define NT_TYPEDEF_CONSTRUCT(func_name) info.construct = func_name ## _construct;

/**
 * NT_TYPEDEF_DESTROY:
 * @func_name: The snake_case of the method name prefix for a type
 *
 * A code value to pass to %NT_DEFINE_TYPE_WITH_CODE which is used to set the destroy method.
 */
#define NT_TYPEDEF_DESTROY(func_name) info.destroy = func_name ## _destroy;

/**
 * NT_TYPEDEF_EXTENDS:
 * @...: The type ID's to extend off of, must end in %NT_TYPE_NONE
 */
#define NT_TYPEDEF_EXTENDS(...) info.extends = (NtType[]){ __VA_ARGS__ };

/**
 * NT_DEFINE_TYPE_WITH_CODE:
 * @ns: All-caps name of the namespace this type is associated with
 * @name: All-caps name of the type in the namespace
 * @struct_name: PascalCase name of the type
 * @func_name: The snake_case of the method name prefix for the type
 * @flgs: The %NtTypeFlags to set
 * @code: The type definition extra code to pass
 *
 * Defines a new basic type. %NT_DEFINE_TYPE is recommended unless
 * you don't want a construct and destroy method.
 */
#define NT_DEFINE_TYPE_WITH_CODE(ns, name, struct_name, func_name, flgs, code) \
  const size_t ns ## _ ## name ## _SIZE = sizeof (struct_name) - sizeof (NtTypeInstance); \
  struct_name * ns ## _ ## name(NtTypeInstance* instance) { \
    return (struct_name *)nt_type_instance_get_data(instance, func_name ## _get_type()); \
  } \
  const bool ns ## _IS_ ## name(struct_name* self) { \
    NtType base = func_name ## _get_type(); \
    NtType child = ((NtTypeInstance*)self)->type; \
    return nt_type_isof(base, child) || base == child; \
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

/**
 * NT_DEFINE_TYPE:
 * @ns: All-caps name of the namespace this type is associated with
 * @name: All-caps name of the type in the namespace
 * @struct_name: PascalCase name of the type
 * @func_name: The snake_case of the method name prefix for the type
 * @flgs: The %NtTypeFlags to set
 * @...: The type ID's to extend off of, must end in %NT_TYPE_NONE
 *
 * Use %NT_DEFINE_TYPE_WITH_CODE and set the construct and destroy methods for it.
 * This is typically the recommended way for making types.
 */
#define NT_DEFINE_TYPE(ns, name, struct_name, func_name, flags, ...) \
  static void func_name ## _construct(NtTypeInstance* instance, NtTypeArgument* arguments); \
  static void func_name ## _destroy(NtTypeInstance* instance); \
  NT_DEFINE_TYPE_WITH_CODE(ns, name, struct_name, func_name, flags, \
    NT_TYPEDEF_CONSTRUCT(func_name) \
    NT_TYPEDEF_DESTROY(func_name) \
    NT_TYPEDEF_EXTENDS(__VA_ARGS__))

/**
 * NT_DECLARE_TYPE:
 * @ns: All-caps name of the namespace this type is associated with
 * @name: All-caps name of the type in the namespace
 * @struct_name: PascalCase name of the type
 * @func_name: The snake_case of the method name prefix for the type
 *
 * Declares a type
 */
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
 * @info: The %NtTypeInfo for the new type
 *
 * Register a new type
 *
 * Returns: The %NtType ID of the new type
 */
NtType nt_type_register(NtTypeInfo* info);

/**
 * nt_type_register:
 * @info: The %NtTypeInfo to unregister
 *
 * Unregisters a type
 */
void nt_type_unregister(NtTypeInfo* info);

/**
 * nt_type_isof:
 * @type: The type to check
 * @base: The base type to look for
 *
 * Checks whether or not @base is extended in @type.
 *
 * Returns: If %true then @type extends @base, otherwise %false is returned.
 */
bool nt_type_isof(NtType type, NtType base);

/**
 * nt_type_info_from_type:
 * @type: The %NtType ID
 *
 * Get type information from a type ID
 * Returns: The type information for @type.
 */
const NtTypeInfo* nt_type_info_from_type(NtType type);

/**
 * nt_type_info_get_total_size:
 * @info: The type info
 *
 * Returns: The total size of the type instance.
 */
const size_t nt_type_info_get_total_size(NtTypeInfo* info);

/**
 * nt_type_instance_new:
 * @type: The %NtType ID to create a new instance of
 * @arguments: The argument to pass
 *
 * Constructs a new type instance.
 *
 * Returns: The new instance of @type
 */
NtTypeInstance* nt_type_instance_new(NtType type, NtTypeArgument* arguments);

/**
 * nt_type_instance_get_data:
 * @instance: The type instance to get data for
 * @type: The type in @instance to look for
 *
 * Gets the instance of type inside of the parent instance
 *
 * Returns: A pointer to where @type's instance data begins at.
 */
NtTypeInstance* nt_type_instance_get_data(NtTypeInstance* instance, NtType type);

/**
 * nt_type_instance_ref:
 * @instance: The type instance to reference
 *
 * Increases the ref_count of the type instance
 */
NtTypeInstance* nt_type_instance_ref(NtTypeInstance* instance);

/**
 * nt_type_instance_unref:
 * @instance: The type instance to unreference
 *
 * Decreases the reference count of the type instance.
 * If the reference count is zero then the type instance is destroyed.
 */
void nt_type_instance_unref(NtTypeInstance* instance);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
