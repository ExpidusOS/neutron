#include <neutron/elemental.h>
#include <check.h>
#include <stdlib.h>
#include <string.h>

static NtTypeArgument arguments[] = {
  { "hello", NT_VALUE_STRING("Hello, world") },
  { NULL }
};

START_TEST(test_default) {
  NtValue value = nt_type_argument_get(arguments, "foo", NT_VALUE_POINTER(NULL));
  ck_assert_uint_eq(value.type, NT_VALUE_TYPE_POINTER);
}
END_TEST

START_TEST(test_exists) {
  NtValue value = nt_type_argument_get(arguments, "hello", NT_VALUE_POINTER(NULL));
  ck_assert_uint_eq(value.type, NT_VALUE_TYPE_STRING);
  ck_assert_str_eq(value.data.string, "Hello, world");
}
END_TEST

START_TEST(test_null) {
  NtValue value = nt_type_argument_get(NULL, "bar", NT_VALUE_POINTER(NULL));
  ck_assert_uint_eq(value.type, NT_VALUE_TYPE_POINTER);
}
END_TEST

int main(void) {
  Suite* s = suite_create("argument");

  TCase* c_default = tcase_create("default");
  tcase_add_test(c_default, test_default);
  suite_add_tcase(s, c_default);

  TCase* c_exists = tcase_create("exists");
  tcase_add_test(c_exists, test_exists);
  suite_add_tcase(s, c_exists);

  TCase* c_null = tcase_create("null");
  tcase_add_test(c_null, test_null);
  suite_add_tcase(s, c_null);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
