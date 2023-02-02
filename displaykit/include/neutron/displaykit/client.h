#pragma once

#include <neutron/displaykit/context.h>

/**
 * SECTION: client
 * @title: Client
 * @short_description: Client API
 */

/**
 * NtDisplayClient:
 * @instance: The %NtTypeInstance associated with this
 */
typedef struct _NtDisplayClient {
  NtTypeInstance instance;
} NtDisplayClient;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_DISPLAY_CLIENT:
 *
 * The %NtType for %NtDisplayClient
 */
#define NT_TYPE_DISPLAY_CLIENT nt_display_client_get_type()
NT_DECLARE_TYPE(NT, DISPLAY_CLIENT, NtDisplayClient, nt_display_client);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
