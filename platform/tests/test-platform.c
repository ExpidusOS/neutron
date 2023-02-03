#include <neutron/platform/platform.h>
#include <check.h>
#include <stdlib.h>
#include <stdio.h>

START_TEST(test_platform_global) {
  NtType id = NT_TYPE_PLATFORM;
  ck_assert_uint_gt(id, 0);
}
END_TEST

int main(void) {
  Suite* s = suite_create("platform");

  TCase* c_global = tcase_create("global");
  tcase_add_test(c_global, test_platform_global);
  suite_add_tcase(s, c_global);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
