#include <neutron/elemental.h>
#include <check.h>
#include <stdlib.h>
#include <string.h>

static void test_signal_handler(NtSignal* signal, NtTypeArgument* arguments, const void* user_data) {
  bool* resultptr = (bool*)user_data;
  *resultptr = true;
}

START_TEST(test_basic) {
  NtSignal* signal = nt_signal_new();

  bool result = false;
  nt_signal_attach(signal, test_signal_handler, &result);

  nt_signal_emit(signal, NULL);
  ck_assert_int_eq(result, true);

  nt_type_instance_destroy((NtTypeInstance*)signal);
}
END_TEST

START_TEST(test_basic_locking) {
  NtSignal* signal = nt_signal_new_locking();

  bool result = false;
  nt_signal_attach(signal, test_signal_handler, &result);

  nt_signal_emit(signal, NULL);
  ck_assert_int_eq(result, true);

  nt_type_instance_destroy((NtTypeInstance*)signal);
}
END_TEST

START_TEST(test_multiple) {
  NtSignal* signal = nt_signal_new();

  bool result = false;
  nt_signal_attach(signal, test_signal_handler, &result);
  
  bool result2 = false;
  nt_signal_attach(signal, test_signal_handler, &result2);

  nt_signal_emit(signal, NULL);
  ck_assert_int_eq(result, true);
  ck_assert_int_eq(result2, true);

  nt_signal_detach(signal, test_signal_handler);
  nt_type_instance_destroy((NtTypeInstance*)signal);
}
END_TEST

int main(void) {
  Suite* s = suite_create("signal");

  TCase* c_basic = tcase_create("basic");
  tcase_add_test(c_basic, test_basic);
  suite_add_tcase(s, c_basic);

  TCase* c_basic_locking = tcase_create("basic-locking");
  tcase_add_test(c_basic_locking, test_basic_locking);
  suite_add_tcase(s, c_basic_locking);

  TCase* c_multiple = tcase_create("multiple");
  tcase_add_test(c_multiple, test_multiple);
  suite_add_tcase(s, c_multiple);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
