#pragma once

#include <neutron/elemental/string.h>
#include <neutron/elemental/type.h>

NT_BEGIN_DECLS

/**
 * SECTION: backtrace
 * @title: Backtrace
 * @short_description: Tracing methods
 */

/**
 * NtBacktraceEntry:
 * @prev: The entry which was called from this
 * @file: The source file
 * @method: The method name
 * @line: The line in the source file
 * @address: The address of the method
 *
 * An entry in the backtrace
 */
typedef struct _NtBacktraceEntry {
  struct _NtBacktraceEntry* prev;
  const char* file;
  const char* method;
  int line;
  void* address;
} NtBacktraceEntry;

/**
 * NtBacktrace:
 * @entries: Linked list of entries
 *
 * Backtrace
 */
typedef struct _NtBacktrace {
  NtTypeInstance instance;

  struct _NtBacktraceEntry* entries;
} NtBacktrace;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_BACKTRACE:
 *
 * The %NtType ID of %NtBacktrace
 */
#define NT_TYPE_BACKTRACE nt_backtrace_get_type()
NT_DECLARE_TYPE(NT, BACKTRACE, NtBacktrace, nt_backtrace);

/**
 * nt_backtrace_new:
 *
 * Creates a new backtrace
 * Returns: An empty backtrace
 */
NtBacktrace* nt_backtrace_new();

/**
 * nt_backtrace_new_auto:
 *
 * Generates a backtrace automatically
 * Returns: A new backtrace containing all of the entries
 */
NtBacktrace* nt_backtrace_new_auto();

/**
 * nt_backtrace_copy:
 * @self: The original backtrace
 *
 * Creates a new backtrace and duplicate its entires to the new one.
 * Returns: A newly allocated backtrace.
 */
NtBacktrace* nt_backtrace_copy(NtBacktrace* self);

/**
 * nt_backtrace_push_full:
 * @self: An instance of a backtrace
 * @file: The source file
 * @method: The method name
 * @line: The line in the source file
 * @address: The address of the method
 *
 * Pushes a new method call onto the trace, it is recommended to use %nt_backtrace_push
 */
void nt_backtrace_push_full(NtBacktrace* self, const char* file, const char* method, int line, void* address);

/**
 * nt_backtrace_push:
 * @self: An instance of a backtrace
 * @address: The address of the method
 *
 * Pushes a new method call onto the trace
 */
#define nt_backtrace_push(self, address) nt_backtrace_push_full(self, __FILE__, __func__, __LINE__, address)

/**
 * nt_backtrace_pop:
 * @self: An instance of a backtrace
 *
 * Pops the last backtrace entry off
 */
void nt_backtrace_pop(NtBacktrace* self);

/**
 * nt_backtrace_to_string:
 * @self: An instance of a backtrace
 *
 * Gets a string representation of the backtrace
 *
 * Returns: A string
 */
NtString* nt_backtrace_to_string(NtBacktrace* self);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
