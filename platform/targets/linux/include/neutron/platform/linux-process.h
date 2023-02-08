#pragma once

#include <neutron/elemental.h>
#include <neutron/platform/process.h>
#include <unistd.h>

/**
 * SECTION: linux-process
 * @title: Linux Process
 * @short_description: A process implementation for Linux
 * @see_also: #NtProcess
 */

/**
 * NtLinuxProcess:
 * @instance: The %NtTypeInstance associated with this
 *
 * A process implementation for Linux
 */
typedef struct _NtLinuxProcess {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtLinuxProcessPrivate* priv;
} NtLinuxProcess;

NT_BEGIN_DECLS

/**
 * NT_TYPE_LINUX_PROCESS:
 *
 * The %NtType ID of %NtLinuxProcess
 */
#define NT_TYPE_LINUX_PROCESS nt_linux_process_get_type()
NT_DECLARE_TYPE(NT, LINUX_PROCESS, NtLinuxProcess, nt_linux_process);

/**
 * nt_linux_process_new:
 * @platform: The platform instance
 * @pid: Process ID
 *
 * Creates a new %NtProcess for Linux which uses a process ID
 *
 * Returns: The %NtProcess instance for the @pid
 */
NtProcess* nt_linux_process_new(NtPlatform* platform, pid_t pid);

NT_END_DECLS
