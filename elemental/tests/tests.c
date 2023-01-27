#include <neutron/elemental.h>
#include <check.h>
#include <stdlib.h>
#include <string.h>

START_TEST(test_argument) {
  NtTypeArgument arguments[] = {
    { "hello", NT_VALUE_STRING("Hello, world") },
    { NULL }
  };

  NtValue value = nt_type_argument_get(arguments, "hello", NT_VALUE_POINTER(NULL));
  ck_assert_uint_eq(value.type, NT_VALUE_TYPE_STRING);
  ck_assert_str_eq(value.data.string, "Hello, world");
}
END_TEST

START_TEST(test_type) {
  NtTypeInfo info = {};
  info.flags = NT_TYPE_FLAG_STATIC;

  NtType id = nt_type_register(&info);
  ck_assert_uint_gt(id, 0);

  nt_type_unregister(&info);
  ck_assert_uint_eq(info.id, 0);
}
END_TEST

static void test_signal_handler(NtSignal* signal, NtTypeArgument* arguments, const void* user_data) {
  bool* resultptr = (bool*)user_data;
  *resultptr = true;
}

START_TEST(test_signal) {
  NtSignal* signal = nt_signal_new();

  bool result = false;
  nt_signal_attach(signal, test_signal_handler, &result);
  nt_signal_emit(signal, NULL);
  ck_assert_int_eq(result, true);

  nt_type_instance_destroy((NtTypeInstance*)signal);
}
END_TEST

int main(void) {
  Suite* s = suite_create("elemental");

  TCase* c_argument = tcase_create("argument");
  tcase_add_test(c_argument, test_argument);
  suite_add_tcase(s, c_argument);

  TCase* c_type = tcase_create("type");
  tcase_add_test(c_type, test_type);
  suite_add_tcase(s, c_type);

  TCase* c_signal = tcase_create("signal");
  tcase_add_test(c_signal, test_signal);
  suite_add_tcase(s, c_signal);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
