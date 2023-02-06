#pragma once

#include <neutron/elemental.h>
#include <neutron/platform/signal.h>
#include <stdint.h>

/**
 * SECTION: process
 * @title: Process
 * @short_description: A process or thread
 */
NT_BEGIN_DECLS

/**
 * NtProcess:
 * @instance: The %NtTypeInstance associated with this
 * @get_id: Retrieve the process ID of this instance of %NtProcess, returns 0 if none exists
 * @priv: Private data
 *
 * A process or a thread
 */
typedef struct _NtProcess {
  NtTypeInstance instance;

  uint64_t (*get_id)(struct _NtProcess* self);
  
  /*< private >*/
  struct _NtProcessPrivate* priv;
} NtProcess;

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_PROCESS:
 *
 * The %NtType ID of %NtProcess
 */
#define NT_TYPE_PROCESS nt_process_get_type()
NT_DECLARE_TYPE(NT, PROCESS, NtProcess, nt_process);

/**
 * nt_process_get_id:
 * @self: Instance of %NtProcess
 *
 * Retrieves the process ID
 *
 * Returns: Any number above 0 if the API was able to get a PID.
 */
uint64_t nt_process_get_id(NtProcess* self);

/**
 * nt_process_attach_signal:
 * @self: Instance of %NtProcess
 * @hanlder: The handler method to execute
 * @data: Data to pass to the handler
 *
 * Attaches a signal handler with user data to the process.
 *
 * Returns: The ID of the signal
 */
int nt_process_attach_signal(NtProcess* self, NtSignalHandler handler, void* data);

/**
 * nt_process_detach_signal:
 * @self: Instance of %NtProcess
 * @id: The ID of the signal
 *
 * Detaches a signal handler with user data to the process.
 *
 * Returns: The data passed by %nt_process_attach_signal
 */
void* nt_process_detach_signal(NtProcess* self, int id);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
