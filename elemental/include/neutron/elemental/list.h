#pragma once

#include <neutron/elemental/type.h>
#include <neutron/elemental/value.h>
#include <string.h>

NT_BEGIN_DECLS

/**
 * SECTION: list
 * @title: List
 * @short_description: A linked-list type which holds %NtValue
 */

/**
 * NtList:
 * @instance: The %NtTypeInstance associated
 * @prev: The previous element
 * @next: The next element
 * @value: The value being held in the list element
 *
 * A linked-list type which holds %NtValue
 */
typedef struct _NtList {
  NtTypeInstance instance;

  struct _NtList* prev;
  struct _NtList* next;
  NtValue value;
} NtList;

/**
 * NT_TYPE_LIST:
 *
 * The %NtType ID of %NtList
 */
#define NT_TYPE_LIST nt_list_get_type()
NT_DECLARE_TYPE(NT, LIST, NtList, nt_list);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * nt_list_alloc:
 * @value: The value to use
 *
 * Allocates a new entry for a list
 *
 * Returns: The entry
 */
NtList* nt_list_alloc(NtValue value);

/**
 * nt_list_get_head:
 * @self: The list
 *
 * Gets the head element of the list
 *
 * Returns: An element
 */
NtList* nt_list_get_head(NtList* self);

/**
 * nt_list_get_tail:
 * @self: The list
 *
 * Gets the tail element of the list
 *
 * Returns: An element
 */
NtList* nt_list_get_tail(NtList* self);

/**
 * nt_list_length:
 * @self: The list
 *
 * Counts the number of elements in the list starting with @self
 * Return: THe number of elements
 */
size_t nt_list_length(NtList* self);

/**
 * nt_list_prepend:
 * @self: The list to use
 * @value: The value to prepend
 *
 * Prepends @value into a new entry in the list.
 * Returns: The new head of the list.
 */
NtList* nt_list_prepend(NtList* self, NtValue value);

/**
 * nt_list_append:
 * @self: The list to use
 * @value: The value to append
 *
 * Appends @value into a new entry in the list.
 * Returns: The new head of the list.
 */
NtList* nt_list_append(NtList* self, NtValue value);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
