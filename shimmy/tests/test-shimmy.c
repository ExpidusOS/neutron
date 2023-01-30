#include <neutron/shimmy.h>
#include <check.h>
#include <setjmp.h>

static void* test_handler(NtShimBinding* binding, void* stack, size_t size) {
  int* data = (int*)stack;
  ck_assert_int_eq(*data, 42);
  return "Hello, world";
}

START_TEST(test_exec) {
  NtShim id = nt_shimmy_bind("test", "test", test_handler);
  ck_assert_int_gt(id, NT_SHIM_NONE);

  int stack = 42;
  const char* ret = (const char*)nt_shimmy_exec("test", "test", &stack, sizeof (stack));
  ck_assert_ptr_nonnull(ret);
  ck_assert_str_eq(ret, "Hello, world");
}
END_TEST

int main(void) {
  Suite* s = suite_create("shimmy");

  TCase* c_exec = tcase_create("exec");
  tcase_add_test(c_exec, test_exec);
  suite_add_tcase(s, c_exec);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
