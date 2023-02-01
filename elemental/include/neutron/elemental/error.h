#pragma once

#include <neutron/elemental/backtrace.h>
#include <neutron/elemental/type.h>

NT_BEGIN_DECLS

/**
 * SECTION: error
 * @title: Error
 * @short_description: Error handler
 */

/**
 * NtError:
 * @instance: The %NtTypeInstance associated
 * @priv: Private data
 *
 * An error
 */
typedef struct _NtError {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtErrorPrivate* priv;
} NtError;

/**
 * NT_TYPE_ERROR:
 *
 * The %NtType ID of %NtError
 */
#define NT_TYPE_ERROR nt_error_get_type()
NT_DECLARE_TYPE(NT, ERROR, NtError, nt_error);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_error_new_full:
 * @file: The file the error comes from
 * @method: The method the error comes from
 * @line: The line in the file the error comes from
 * @message: The error message
 * @backtrace: The backtrace of the error
 *
 * Fully creates a new error, it is recommended to use %nt_error_new
 *
 * Returns: A new error
 */
NtError* nt_error_new_full(const char* file, const char* method, int line, const char* message, NtBacktrace* backtrace);

/**
 * nt_error_new:
 * @message: The error message
 * @backtrace: The backtrace of the error
 *
 * Returns: A new error
 */
#define nt_error_new(message, backtrace) nt_error_new(__FILE__, __func__, __LINE__, message, backtrace)

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
