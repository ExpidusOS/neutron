#pragma once

#include <neutron/elemental.h>

NT_BEGIN_DECLS

/**
 * SECTION: shimmy
 * @title: Shimmy
 * @short_description: Shims for Neutron
 */

struct _NtShimBinding;

/**
 * NtShim:
 *
 * ID of a bounded shim
 */
typedef uintptr_t NtShim;

/**
 * NT_SHIM_NONE:
 *
 * ID of an unbounded or invalid shim
 */
#define NT_SHIM_NONE 0

/**
 * NtShimBinding:
 * @binding: The binding which was executed
 * @data: The data to pass
 * @data_size: The size of the data
 *
 * Method binding handler for a shim
 *
 * Returns: The result of the binded method
 */
typedef void* (*NtShimMethod)(struct _NtShimBinding* binding, void* data, size_t data_size);

/**
 * NtShimBinding:
 * @lib: Library name
 * @method: Method name
 * @handler: Method handler to execute
 * @id: The ID of the bounded shim
 *
 * A structure for a shim binding
 */
typedef struct _NtShimBinding {
  const char* lib;
  const char* method;
  NtShimMethod handler;
  NtShim id;
} NtShimBinding;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_shimmy_bind:
 * @lib: Library name
 * @method: Method name
 * @handler: Method handler to execute
 *
 * Binds a shim with Shimmy.
 *
 * Returns: The ID of the bounded shim.
 */
NtShim nt_shimmy_bind(const char* lib, const char* method, NtShimMethod handler);

/**
 * nt_shimmy_find:
 * @lib: Library name
 * @method: Method name
 *
 * Finds a shim's ID by its library and method name.
 * Returns: A shim ID
 */
NtShim nt_shimmy_find(const char* lib, const char* method);

/**
 * nt_shimmy_get_shim:
 * @id: ID of the shim
 *
 * Looks for the shim binding and returns it.
 * Returns: A shim binding
 */
NtShimBinding* nt_shimmy_get_shim(NtShim id);

/**
 * nt_shimmy_unbind:
 * @id: ID of the shim
 *
 * Unbinds a shim by its ID.
 */
void nt_shimmy_unbind(NtShim id);

/**
 * nt_shimmy_get_reg:
 *
 * Gets the registry address.
 * This is used internally for binding into a child process.
 */
void* nt_shimmy_get_reg();

/**
 * nt_shimmy_exec:
 * @lib: Library name
 * @method: Method name
 * @data: The data to pass
 * @data_size: The size of the data
 *
 * Executes a shim
 *
 * Returns: Data returned from execution.
 */
void* nt_shimmy_exec(const char* lib, const char* method, void* data, size_t data_size);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
