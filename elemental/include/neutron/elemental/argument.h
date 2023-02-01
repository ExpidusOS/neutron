#pragma once

#include <neutron/elemental/common.h>
#include <neutron/elemental/value.h>

NT_BEGIN_DECLS

/**
 * SECTION: argument
 * @title: Argument
 * @short_description: Handling of arguments for types and signals
 */

/**
 * NtTypeArgument:
 * @name: Argument name
 * @value: Argument value
 *
 * A structure which holds a single argument for %NtTypeInstance and %NtSignal.
 */
typedef struct _NtTypeArgument {
  const char* name;
  NtValue value;
} NtTypeArgument;

/**
 * NT_TYPE_ARGUMENT_KEY:
 * @struct_name: A PascalCase name, typically the name of the structure this goes with
 * @key: A kebab-case name
 *
 * A simple macro for generating names for arguments
 *
 * Returns: A static string with @struct_name and @key appended to each other but separated with "::"
 */
#define NT_TYPE_ARGUMENT_KEY(struct_name, key) #struct_name "::" #key

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_type_argument_get:
 * @arguments: A list of %NtTypeArgument
 * @name: The name of the argument to get
 * @default_value: The value to return if @arguments does not contain @name
 *
 * Gets the argument as defined by @name in @arguments.
 * If @name is not in @arguments, then return @default_value.
 *
 * Returns: An %NtValue of either an %NtTypeArgument value or @default_value.
 */
NtValue nt_type_argument_get(NtTypeArgument* arguments, const char* name, NtValue default_value);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
