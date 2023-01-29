#pragma once

#include <neutron/elemental/common.h>
#include <stdbool.h>

NT_BEGIN_DECLS

/**
 * SECTION: value
 * @title: Value
 * @short_description: Value holding
 */

/**
 * NtValueType:
 * @NT_VALUE_TYPE_POINTER: A pointer type
 * @NT_VALUE_TYPE_STRING: A string type
 * @NT_VALUE_TYPE_NUMBER: An integer type
 * @NT_VALUE_TYPE_BOOL: A boolean type
 * @NT_VALUE_TYPE_INSTANCE: An %NtTypeInstance type
 *
 * An enum for describing what %NtValue is holding
 */
typedef enum _NtValueType {
  NT_VALUE_TYPE_POINTER = 0,
  NT_VALUE_TYPE_STRING,
  NT_VALUE_TYPE_NUMBER,
  NT_VALUE_TYPE_BOOL,
  NT_VALUE_TYPE_INSTANCE
} NtValueType;

struct _NtTypeInstance;

/**
 * NtValueData:
 * @pointer: Data being held as a pointer
 * @string: Data being held as a string
 * @number: Data being held as a number
 * @boolean: Data being held as a boolean
 * @instance: Data being held as an %NtTypeInstance
 *
 * A union for holding data in %NtValue
 */
typedef union _NtValueData {
  void* pointer;
  char* string;
  int number;
  bool boolean;
  struct _NtTypeInstance* instance;
} NtValueData;

/**
 * NtValue:
 * @type: The type of value
 * @data: The data being held
 *
 * A static structure type for holding different kinds of data
 */
typedef struct _NtValue {
  NtValueType type;
  NtValueData data;
} NtValue;

/**
 * NT_VALUE_DATA_INIT:
 * @key: The key name
 * @value: The value to set
 *
 * Initializes %NtValueData with a value
 */
#define NT_VALUE_DATA_INIT(key, value) ((NtValueData){ .key = value, })

/**
 * NT_VALUE_INIT:
 * @type: The %NtValueType to set as
 * @key: The key to pass to %NT_VALUE_DATA_INIT
 * @value: The value to pass to %NT_VALUE_DATA_INIT
 *
 * Fully initializes %NtValue
 */
#define NT_VALUE_INIT(type, key, value) ((NtValue){ type, NT_VALUE_DATA_INIT(key, value) })

/**
 * NT_VALUE_POINTER:
 * @value: The %void* value
 *
 * Creates a new %NT_VALUE_TYPE_POINTER in %NtValue holding @value
 */
#define NT_VALUE_POINTER(value) NT_VALUE_INIT(NT_VALUE_TYPE_POINTER, pointer, value)

/**
 * NT_VALUE_STRING:
 * @value: The %char* value
 *
 * Creates a new %NT_VALUE_TYPE_STRING in %NtValue holding @value
 */
#define NT_VALUE_STRING(value) NT_VALUE_INIT(NT_VALUE_TYPE_STRING, string, value)

/**
 * NT_VALUE_NUMBER:
 * @value: The %int value
 *
 * Creates a new %NT_VALUE_TYPE_NUMBER in %NtValue holding @value
 */
#define NT_VALUE_NUMBER(value) NT_VALUE_INIT(NT_VALUE_TYPE_NUMBER, number, value)

/**
 * NT_VALUE_NUMBER:
 * @value: The %bool value
 *
 * Creates a new %NT_VALUE_TYPE_BOOL in %NtValue holding @value
 */
#define NT_VALUE_BOOL(value) NT_VALUE_INIT(NT_VALUE_TYPE_BOOL, boolean, value)

/**
 * NT_VALUE_INSTANCE:
 * @value: The %NtTypeInstance value
 *
 * Creates a new %NT_VALUE_TYPE_INSTANCE in %NtValue holding @value
 */
#define NT_VALUE_INSTANCE(value) NT_VALUE_INIT(NT_VALUE_TYPE_INSTANCE, instance, value)

NT_END_DECLS
