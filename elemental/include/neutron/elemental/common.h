#pragma once

/**
 * SECTION: common
 * @title: Common
 * @short_description: Common macros which are used throughout Neutron
 */

/**
 * NT_PUBLIC:
 *
 * Prepend to a method or variable to make it public
 */

/**
 * NT_PRIVATE:
 *
 * Prepend to a method or variable to make it private
 */

/**
 * NT_BEGIN_DECLS:
 *
 * Add before you declare any methods or variable to make them visible to C++.
 */

/**
 * NT_END_DECLS:
 *
 * Add after you declare any methods or variable to make them visible to C++.
 */

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
