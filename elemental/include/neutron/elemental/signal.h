#pragma once

#include <neutron/elemental/type.h>

NT_BEGIN_DECLS

/**
 * SECTION: signal
 * @title: Signal
 * @short_description: Signal handling
 */

/**
 * NtSignal:
 * @instance: The %NtTypeInstance associated
 * @priv: Private data
 *
 * A signal
 */
typedef struct _NtSignal {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtSignalPrivate* priv;
} NtSignal;

/**
 * NT_TYPE_SIGNAL:
 *
 * The %NtType ID of %NtSignal
 */
#define NT_TYPE_SIGNAL nt_signal_get_type()
NT_DECLARE_TYPE(NT, SIGNAL, NtSignal, nt_signal);

/**
 * NtSignalHandler:
 * @signal: The signal which was emitted
 * @arguments: The arguments passed to the emit method
 * @data: User data
 *
 * Method type used for signal emittion.
 */
typedef void (*NtSignalHandler)(NtSignal* signal, NtTypeArgument* arguments, const void* data);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_signal_new:
 *
 * A new non-blocking signal
 *
 * Returns: A new %NtSignal
 */
NtSignal* nt_signal_new();

/**
 * nt_signal_new_locking:
 *
 * A new signal which locks every time nt_signal_emit is called
 *
 * Returns: A new %NtSignal
 */
NtSignal* nt_signal_new_locking();

/**
 * nt_signal_attach:
 * @self: The %NtSignal
 * @handler: The handler to add
 * @data: The data to send to @handler
 *
 * Attaches a handler to the signal
 */
void nt_signal_attach(NtSignal* self, NtSignalHandler handler, const void* data);

/**
 * nt_signal_detach:
 * @self: The %NtSignal
 * @handler: The handler to add
 *
 * Detaches @handler from the signal
 */
void nt_signal_detach(NtSignal* self, NtSignalHandler handler);

/**
 * nt_signal_emit:
 * @self: The %NtSignal
 * @arguments: The arguments to send to %NtSignalHandler
 *
 * Triggers signal execution
 */
void nt_signal_emit(NtSignal* self, NtTypeArgument* arguments);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
