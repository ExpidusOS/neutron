#pragma once

#include <neutron/elemental/type.h>

NT_BEGIN_DECLS

typedef struct _NtSignal {
  NtTypeInstance instance;
  struct _NtSignalPrivate* priv;
} NtSignal;

#define NT_TYPE_SIGNAL nt_signal_get_type()
NT_DECLARE_TYPE(NT, SIGNAL, NtSignal, nt_signal);

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
 */
NtSignal* nt_signal_new();

/**
 * nt_signal_new_locking:
 *
 * A new signal which locks every time nt_signal_emit is called
 */
NtSignal* nt_signal_new_locking();

/**
 * nt_signal_attach:
 *
 * Attaches a handler to the signal
 */
void nt_signal_attach(NtSignal* self, NtSignalHandler handler, const void* data);

/**
 * nt_signal_detach:
 *
 * Detaches handler from the signal
 */
void nt_signal_detach(NtSignal* self, NtSignalHandler handler);

/**
 * nt_signal_emit:
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
