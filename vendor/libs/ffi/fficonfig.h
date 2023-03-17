#ifndef __FFI_CONFIG_H_
#define __FFI_CONFIG_H_ 1

#define STDC_HEADERS 1
#define HAVE_MEMCPY 1

#ifndef FFI_HIDDEN
#ifdef LIBFFI_ASM
#ifdef __APPLE__
#define FFI_HIDDEN(name) .private_extern name
#else
#define FFI_HIDDEN(name) .hidden name
#endif
#else
#define FFI_HIDDEN __attribute__ ((visibility ("hidden")))
#endif
#else
#ifdef LIBFFI_ASM
#define FFI_HIDDEN(name)
#else
#define FFI_HIDDEN
#endif
#endif

#endif
