#pragma once

#include <neutron/elemental.h>
#include <stdint.h>

/**
 * SECTION: signal
 * @title: Signal
 * @short_description: Signaling for handling interrupts and exceptions
 */
NT_BEGIN_DECLS

/**
 * NtException:
 * @NT_PROCESS_EXCEPTION_NONE: No process exception
 * @NT_PROCESS_EXCEPTION_SEG_VIO: A segment violation occurred
 * @NT_PROCESS_EXCEPTION_ILL_INSTR: An illegal instruction was executed
 * @NT_PROCESS_EXCEPTION_ILL_MATH: An illegal mathematical operation was executed
 * @NT_PROCESS_EXCEPTION_HW_BUS: A bus error was raised
 *
 * Enum of different kinds of exceptions
 */
typedef enum _NtException {
  NT_PROCESS_EXCEPTION_NONE = 0,
  NT_PROCESS_EXCEPTION_SEG_VIO,
  NT_PROCESS_EXCEPTION_ILL_INSTR,
  NT_PROCESS_EXCEPTION_ILL_MATH,
  NT_PROCESS_EXCEPTION_HW_BUS
} NtException;

/**
 * NtInterrupt:
 * @NT_PROCESS_INTERRUPT_NONE: No process interrupt
 * @NT_PROCESS_INTERRUPT_DBG_STOP: Debugger wants the process to stop
 * @NT_PROCESS_INTERRUPT_DBG_CONT: Debugger wants the process to continue
 * @NT_PROCESS_INTERRUPT_QUIT: Process was told to quit
 * @NT_PROCESS_INTERRUPT_KILL: Process was told to kill
 * @NT_PROCESS_INTERRUPT_EXIT: Process was told to exit
 *
 * Enum of different kinds of interrupts
 */
typedef enum _NtInterrupt {
  NT_PROCESS_INTERRUPT_NONE = 0,
  NT_PROCESS_INTERRUPT_DBG_STOP,
  NT_PROCESS_INTERRUPT_DBG_CONT,
  NT_PROCESS_INTERRUPT_QUIT,
  NT_PROCESS_INTERRUPT_KILL,
  NT_PROCESS_INTERRUPT_EXIT
} NtInterrupt;

/**
 * NtSignalResult:
 * @NT_SIGNAL_STOP: Stops all signaling
 * @NT_SIGNAL_CONTINUE: Continues signal execution
 * @NT_SIGNAL_RETURN: Makes the process continue after the signal
 * @NT_SIGNAL_QUIT: Quit the process after the signal
 *
 * Enums of different results %NtSignalHandler could return
 */
typedef enum _NtSignalResult {
  NT_SIGNAL_STOP = 0 << 0,
  NT_SIGNAL_CONTINUE = 1 << 0,
  NT_SIGNAL_RETURN = 0 << 1,
  NT_SIGNAL_QUIT = 1 << 1
} NtSignalResult;

struct _NtProcess;
struct _NtSignal;

/**
 * NtSignalHandler:
 * @proc: The process which was signaled
 * @signal: The signaling data
 * @data: User data to pass to the handler
 *
 * A method for handling signals
 *
 * Returns: A mask of different %NtSignalResult flags which controls how the process should exit
 */
typedef NtSignalResult (*NtSignalHandler)(struct _NtProcess* proc, struct _NtSignal* signal, void* data);

/**
 * NtSignalException:
 * @kind: The kind of exception
 *
 * Signaling data for an exception
 */
typedef struct _NtSignalException {
  NtException kind;
} NtSignalException;

/**
 * NtSignalInterrupt:
 * @kind: The kind of interrupt
 *
 * Signaling data for an interrupt
 */
typedef struct _NtSignalInterrupt {
  NtInterrupt kind;
} NtSignalInterrupt;

/**
 * NtSignal:
 * @is_interrupt: Bit value of if the signal was an interrupt
 * @is_exception: Bit value of if the signal was an exception
 * @stack: Pointer to the stack
 * @address: Pointer to the address
 * @exception: Data for an exception
 * @interrupt: Data for an interrupt
 *
 * Signaling data
 */
typedef struct _NtSignal {
  bool is_interrupt:1;
  bool is_exception:1;

  void* stack;
  void* address;

  union {
    NtSignalException exception;
    NtSignalInterrupt interrupt;
  };
} NtSignal;

NT_END_DECLS
