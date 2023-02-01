#include <neutron/elemental.h>
#include <check.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

START_TEST(test_auto) {
  NtBacktrace* backtrace = nt_backtrace_new_auto();
  ck_assert_ptr_nonnull(backtrace);
  ck_assert_ptr_nonnull(backtrace->entries);

  size_t i = 0;
  for (NtBacktraceEntry* entry = backtrace->entries; entry != NULL; entry = entry->prev, i++) {
    printf("%d. %s:%d %s (%p)\n", i, entry->file, entry->line, entry->method, entry->address);
  }

  nt_type_instance_unref((NtTypeInstance*)backtrace);
}
END_TEST

int main(void) {
  Suite* s = suite_create("backtrace");

  TCase* c_auto = tcase_create("auto");
  tcase_add_test(c_auto, test_auto);
  suite_add_tcase(s, c_auto);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
