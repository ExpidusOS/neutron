#pragma once

#include <neutron/elemental/type.h>
#include <stdarg.h>

/**
 * SECTION: string
 * @title: String
 * @short_description: A type for modifying and handling strings
 */

/**
 * NtString:
 * @instance: The %NtTypeInstance associated
 * @priv: Private data
 */
typedef struct _NtString {
  NtTypeInstance instance;

  /*< private >*/
  struct _NtStringPrivate* priv;
} NtString;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_STRING:
 *
 * The %NtType ID of %NtString
 */
#define NT_TYPE_STRING nt_string_get_type()
NT_DECLARE_TYPE(NT, STRING, NtString, nt_string);

/**
 * nt_string_new:
 * @value: The string
 *
 * Creates a new string instance and automatically determines the length of it.
 *
 * Returns: A new string instance
 */
NtString* nt_string_new(char* value);

/**
 * nt_string_new_alloc:
 * @length: The length of the string
 * @c: The character to fill the string with
 *
 * Allocates a new string filled with @c with the specified length.
 *
 * Returns: A new string instance
 */
NtString* nt_string_new_alloc(size_t length, char c);

/**
 * nt_string_new_full:
 * @value: The string
 * @length: Length of the string
 *
 * Creates a new string instance with the value and length already defined.
 *
 * Returns: A new string instance
 */
NtString* nt_string_new_full(char* value, size_t length);

/**
 * nt_string_set_dynamic:
 * @self: The instance of the string type
 * @value: The string to set this to
 *
 * Copies the string and reallocate if needed.
 * It can also shrink the string if needed.
 */
void nt_string_set_dynamic(NtString* self, const char* value);

/**
 * nt_string_set_fixed:
 * @self: The instance of the string type
 * @value: The string to set this to
 *
 * Copies @value's characters into @self.
 * If the length of @value is greater than the string is allocated for, then it cuts off.
 */
void nt_string_set_fixed(NtString* self, const char* value);

/**
 * nt_string_set_fixed_strict:
 * @self: The instance of the string type
 * @value: The string to set this to
 *
 * This is a stricter version of %nt_string_set_fixed.
 * If the length of @value is greater than the string is allocated for, then it fails.
 */
void nt_string_set_fixed_strict(NtString* self, const char* value);

/**
 * nt_string_dynamic_printf:
 * @self: The instance of the string type
 * @fmt: printf format string
 * @ap: Arguments for the printf
 *
 * Performs a dynamically reallocated size printf on the string.
 */
void nt_string_dynamic_printf(NtString* self, const char* fmt, ...) __attribute__((format(printf, 2, 3)));

/**
 * nt_string_fixed_printf:
 * @self: The instance of the string type
 * @fmt: printf format string
 * @ap: Arguments for the printf
 *
 * Performs a fixed size printf on the string.
 */
void nt_string_fixed_printf(NtString* self, const char* fmt, ...) __attribute__((format(printf, 2, 3)));

/**
 * nt_string_dynamic_vprintf:
 * @self: The instance of the string type
 * @fmt: printf format string
 * @ap: Arguments for the printf
 *
 * Performs a dynamically reallocated size printf on the string.
 */
void nt_string_dynamic_vprintf(NtString* self, const char* fmt, va_list ap);

/**
 * nt_string_fixed_vprintf:
 * @self: The instance of the string type
 * @fmt: printf format string
 * @ap: Arguments for the printf
 *
 * Performs a fixed size printf on the string.
 */
void nt_string_fixed_vprintf(NtString* self, const char* fmt, va_list ap);

/**
 * nt_string_fixed_append:
 * @self: The instance of the string type
 * @str: The string to append
 *
 * Appends the string but only if it fits in the allocated space.
 */
void nt_string_fixed_append(NtString* self, const char* str);

/**
 * nt_string_dynamic_append:
 * @self: The instance of the string type
 * @str: The string to append
 *
 * Appends the string but reallocate the string if there is not enough space.
 */
void nt_string_dynamic_append(NtString* self, const char* str);

/**
 * nt_string_fixed_prepend:
 * @self: The instance of the string type
 * @str: The string to append
 *
 * Prepends the string but only if it fits in the allocated space.
 */
void nt_string_fixed_prepend(NtString* self, const char* str);

/**
 * nt_string_dynamic_preppend:
 * @self: The instance of the string type
 * @str: The string to append
 *
 * Prepends the string but reallocate the string if there is not enough space.
 */
void nt_string_dynamic_prepend(NtString* self, const char* str);

/**
 * nt_string_get_value:
 * @self: The instance of the string type
 * @length: An optional pointer for storing the length
 *
 * Gets the string value in %NtString, it can also be used to get the length.
 *
 * Returns: If the string is not initialized then it returns %NULL. Otherwise it returns a newly allocated string.
 */
const char* nt_string_get_value(NtString* self, size_t* length);

/**
 * nt_string_get_length:
 * @self: The instance of the string type
 *
 * Gets the length of the string
 *
 * Returns: A number which is the length of the string value
 */
size_t nt_string_get_length(NtString* self);

/**
 * nt_string_has_prefix:
 * @self: The instance of the string type
 * @prefix: The prefix string
 *
 * Checks whether or not the string starts with @prefix.
 *
 * Returns: %TRUE if @self starts with @prefix's value, %FALSE if not.
 */
bool nt_string_has_prefix(NtString* self, const char* prefix);

/**
 * nt_string_has_suffix:
 * @self: The instance of the string type
 * @prefix: The suffix string
 *
 * Checks whether or not the string ends with @suffix.
 *
 * Returns: %TRUE if @self ends with @suffix's value, %FALSE if not.
 */
bool nt_string_has_suffix(NtString* self, const char* suffix);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
