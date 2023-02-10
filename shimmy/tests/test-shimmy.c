#include <neutron/shimmy.h>
#include <check.h>

static void* test_handler(NtShimBinding* binding, void* stack) {
  int* data = (int*)stack;
  ck_assert_int_eq(*data, 42);
  *data = 43;
  return "Hello, world";
}

START_TEST(test_exec) {
  NtShim id = nt_shimmy_bind("test", "test", test_handler);
  ck_assert_int_gt(id, NT_SHIM_NONE);

  NtPlatform* platform = nt_platform_get_global();
  ck_assert_ptr_nonnull(platform);

  NtProcess* proc = nt_platform_get_current_process(platform);
  ck_assert_ptr_nonnull(proc);

  int stack = 42;
  const char* ret = (const char*)nt_shimmy_exec(proc, "test", "test", &stack);
  ck_assert_int_eq(stack, 43);
  ck_assert_ptr_nonnull(ret);

  nt_shimmy_unbind(id);

  NtShimBinding* binding = nt_shimmy_get_shim(id);
  ck_assert_ptr_null(binding);

  id = nt_shimmy_find("test", "test");
  ck_assert_int_eq(id, NT_SHIM_NONE);
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
