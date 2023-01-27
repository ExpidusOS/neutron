#pragma once

#include <neutron/elemental/common.h>
#include <stdbool.h>

NT_BEGIN_DECLS

/**
 * NtValueType:
 *
 * An enum for describing what NtValue is holding
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
 *
 * A union for holding data in NtValue
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
 *
 * A struct for holding different kinds of values
 */
typedef struct _NtValue {
  /**
   * The type of value
   */
  NtValueType type;

  /**
   * The data being held
   */
  NtValueData data;
} NtValue;

#define NT_VALUE_DATA_INIT(key, value) ((NtValueData){ .key = value, })

#define NT_VALUE_INIT(type, key, value) ((NtValue){ type, NT_VALUE_DATA_INIT(key, value) })
#define NT_VALUE_POINTER(value) NT_VALUE_INIT(NT_VALUE_TYPE_POINTER, pointer, value)
#define NT_VALUE_STRING(value) NT_VALUE_INIT(NT_VALUE_TYPE_STRING, string, value)
#define NT_VALUE_NUMBER(value) NT_VALUE_INIT(NT_VALUE_TYPE_NUMBER, number, value)
#define NT_VALUE_BOOL(value) NT_VALUE_INIT(NT_VALUE_TYPE_BOOL, boolean, value)
#define NT_VALUE_INSTANCE(value) NT_VALUE_INIT(NT_VALUE_TYPE_INSTANCE, instance, value)

NT_END_DECLS
