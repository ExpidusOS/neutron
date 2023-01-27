#pragma once

#if defined(__GNUC__) || defined(__clang__)
#define NT_PUBLIC __attribute__((visibility("default")))
#define NT_PRIVATE __attribute__((visibility("default")))
#elif defined(_WIN32) || defined(__CYGWIN__)
#define NT_PUBLIC __declspec(dllimport)
#define NT_PRIVATE
#else
#warn "Unsupport compiler"
#define NT_PUBLIC
#define NT_PRIVATE
#endif

#ifdef __cplusplus
#define NT_BEGIN_DECLS extern "C" {
#define NT_END_DECLS }
#else
#define NT_BEGIN_DECLS
#define NT_END_DECLS
#endif
