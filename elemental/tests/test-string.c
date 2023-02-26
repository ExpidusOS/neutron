#include <neutron/elemental.h>
#include <check.h>
#include <stdlib.h>
#include <string.h>

START_TEST(test_printf) {
  NtString* obj = nt_string_new(NULL);
  ck_assert_ptr_nonnull(obj);

  nt_string_dynamic_printf(obj, "ABC:%d", 123);

  const char* str = nt_string_get_value(obj, NULL);
  ck_assert_str_eq(str, "ABC:123");
  free(str);

  nt_type_instance_unref((NtTypeInstance*)obj);
}
END_TEST

int main(void) {
  Suite* s = suite_create("string");

  TCase* c_printf = tcase_create("printf");
  tcase_add_test(c_printf, test_printf);
  suite_add_tcase(s, c_printf);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
