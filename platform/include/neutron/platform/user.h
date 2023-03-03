#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: user
 * @title: User
 * @short_description: User API
 */

/**
 * NtUser:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * An %NtTypeInstance for handling a user
 */
typedef struct _NtUser {
  NtTypeInstance instance;
} NtUser;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_USER:
 *
 * The %NtType ID of %NtUser
 */
#define NT_TYPE_USER nt_user_get_type()
NT_DECLARE_TYPE(NT, USER, NtUser, nt_user);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
