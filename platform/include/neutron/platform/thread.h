#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: thread
 * @title: Thread
 * @short_description: A thread API
 */

/**
 * NtThread:
 * @instance: The %NtTypeInstance associated with this
 * @priv: Private data
 *
 * An %NtTypeInstance used for creating threads
 */
typedef struct _NtThread {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtThreadPrivate* priv;
} NtThread;

/**
 * NtThreadMethod:
 * @thread: The thread calling the method
 * @data: The user data
 *
 * Returns: Anything the method wants to return
 */
typedef void* (*NtThreadMethod)(NtThread* thread, const void* data);

/**
 * NtThreadClosure:
 * @method: The method
 * @data: The user data
 *
 * A structure representing closure info on an attached method
 */
typedef struct _NtThreadClosure {
  NtThreadMethod method;
  const void* data;
} NtThreadClosure;

/**
 * NtThreadState:
 * @NT_THREAD_STATE_NONE: The thread has been allocated but it hasn't started
 * @NT_THREAD_STATE_RUNNING: The thread is running
 *
 * Enum for different states a thread could be in
 */
typedef enum _NtThreadState {
  NT_THREAD_STATE_NONE = 0,
  NT_THREAD_STATE_RUNNING
} NtThreadState;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_THREAD:
 *
 * The %NtType ID of %NtThread
 */
#define NT_TYPE_THREAD nt_thread_get_type()
NT_DECLARE_TYPE(NT, THREAD, NtThread, nt_thread);

/**
 * nt_thread_new:
 *
 * Creates a new thread.
 *
 * Returns: A new thread
 */
NtThread* nt_thread_new();

/**
 * nt_thread_new_current:
 * 
 * Creates an instance of %NtThread which represents the thread which called this method.
 * 
 * Returns: A thread which represents the current thread
 */
NtThread* nt_thread_new_current();

/**
 * nt_thread_attach_method:
 * @self: The thread
 * @method: The method
 * @data: The data to pass to the method
 *
 * Attaches @method to execute on this thread.
 *
 * Returns: A number representing the ID of the method
 */
int nt_thread_attach_method(NtThread* self, NtThreadMethod method, const void* data);

/**
 * nt_thread_detach_method:
 * @self: The thread
 * @id: The ID of the method
 *
 * Detaches a method by its ID from executing on the thread.
 *
 * Returns: The user data passed
 */
void* nt_thread_detach_method(NtThread* self, int id);

/**
 * nt_thread_set_main:
 * @self: The thread
 * @method: The method
 * @data: The data to pass to the method
 *
 * Sets the thread's main method which executes after the attached methods.
 * If the thread already has a main, then the old main is returned as a closure.
 *
 * Returns: The closure info on the old main and its data.
 */
NtThreadClosure nt_thread_set_main(NtThread* self, NtThreadMethod method, const void* data);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
