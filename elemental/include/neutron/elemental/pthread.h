#pragma once

#include <neutron/elemental/build.h>

/**
 * SECTION: pthread
 * @title: Pthread
 * @short_description: POSIX's pthread compatibility header
 *
 * This header maps OS specific methods to pthread compatible functions.
 * This serves as a compatibility layer or a loader for pthread for when
 * it is required. This is typically used on Windows when POSIX is not available.
 */

#if defined(NT_HAS_POSIX)
#include <pthread.h>
#elif defined(NT_IS_WINDOWS) || defined(NT_IS_CYGWIN)
#include <windows.h>

#define PTHREAD_MUTEX_INITIALIZER NULL
typedef HANDLE pthread_mutex_t;

static inline int pthread_mutex_init(volatile pthread_mutex_t* mx, void* attrs) {
  if (*mx != NULL) return -1;

  HANDLE p = CreateMutex(NULL, FALSE, NULL);
  if (InterlockedCompareExchangePointer((PVOID*)mx, (PVOID)p, NULL) != NULL) CloseHandle(p);
  return 0;
}

static inline int pthread_mutex_lock(volatile pthread_mutex_t* mx) {
  if (*mx == NULL) {
    int r = pthread_mutex_init(mx, NULL);
    if (r != 0) return r;
  }
  return WaitForSingleObject(*mx, INFINITE) == WAIT_FAILED;
}

#define pthread_mutex_destroy(mx) (CloseHandle(*mx) == 0)
#define pthread_mutex_unlock(mx) (ReleaseMutex(*mx) == 0)
#else
#error "POSIX is not supported on this setup"
#endif
