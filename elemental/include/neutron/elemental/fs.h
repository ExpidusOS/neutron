#pragma once

#include <neutron/elemental/error.h>
#include <neutron/elemental/string.h>
#include <neutron/elemental/type.h>
#include <stdarg.h>

NT_BEGIN_DECLS

/**
 * SECTION: fs
 * @title: Basic File System
 * @short_description: Simple methods and types for handling the most basic file system actions
 */

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_join_path:
 * @prefix: The beginning part of the string
 * @...: More strings to join at the end of the path but ends in %NULL
 *
 * Joins all strings together with the path separator.
 *
 * Returns: A string
 */
const char* nt_join_path(const char* prefix, ...);

/**
 * nt_join_path:
 * @prefix: The beginning part of the string
 * @ap: The arguments of strings to join
 *
 * Joins all strings together with the path separator.
 *
 * Returns: A string
 */
const char* nt_join_pathv(const char* prefix, va_list ap);

/**
 * nt_read_file:
 * @path: Path to the file
 * @backtrace: The backtrace to use
 * @error: Pointer to store the error
 *
 * Reads the file which has the path of @path
 *
 * Returns: A string which is the contents of the file
 */
const char* nt_read_file(const char* path, NtBacktrace* backtrace, NtError** error);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
