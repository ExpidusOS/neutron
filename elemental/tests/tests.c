#include <neutron/elemental/type.h>
#include <check.h>
#include <stdlib.h>
#include <stdio.h>

START_TEST(test_type_basic) {
  NtTypeInfo info = {};
  info.flags = NT_TYPE_FLAG_STATIC;

  NtType id = nt_type_register(&info);
  ck_assert_uint_gt(id, 0);

  nt_type_unregister(&info);
  ck_assert_uint_eq(info.id, 0);
}
END_TEST

int main(void) {
  Suite* s = suite_create("type");

  TCase* c_reg = tcase_create("basic");
  tcase_add_test(c_reg, test_type_basic);
  suite_add_tcase(s, c_reg);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}