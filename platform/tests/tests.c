#include <neutron/platform/platform.h>
#include <check.h>
#include <stdlib.h>
#include <stdio.h>

START_TEST(test_platform_basic) {
  NtType id = NT_TYPE_PLATFORM;
  ck_assert_uint_gt(id, 0);

  NtPlatform* global = nt_platform_get_global();
  ck_assert_ptr_nonnull(global);
  ck_assert_uint_eq(global->instance.ref_count, 1);
}
END_TEST

int main(void) {
  Suite* s = suite_create("platform");

  TCase* c_reg = tcase_create("basic");
  tcase_add_test(c_reg, test_platform_basic);
  suite_add_tcase(s, c_reg);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
