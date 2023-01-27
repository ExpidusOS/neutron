#pragma once

#include <neutron/elemental/common.h>
#include <neutron/elemental/value.h>

NT_BEGIN_DECLS

/**
 * NtTypeArgument:
 *
 * An entry for a type argument
 */
typedef struct _NtTypeArgument {
  /**
   * Name of the argument
   */
  const char* name;

  /**
   * Value of the argument
   */
  NtValue value;
} NtTypeArgument;

#define NT_TYPE_ARGUMENT_KEY(struct_name, key) #struct_name "::" #key

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_type_argument_get:
 *
 * Gets the value of a type argument list, if not found then it returns default_value.
 */
NtValue nt_type_argument_get(NtTypeArgument* arguments, const char* name, NtValue default_value);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
