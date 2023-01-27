#include <neutron/elemental.h>
#include <check.h>
#include <stdlib.h>
#include <string.h>

typedef struct _NtTestObject {
  NtTypeInstance instance;
} NtTestObject;

NT_DECLARE_TYPE(NT, TEST_OBJECT, NtTestObject, nt_test_object);
NT_DEFINE_TYPE(NT, TEST_OBJECT, NtTestObject, nt_test_object, NT_TYPE_FLAG_STATIC);

static void nt_test_object_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtTestObject* self = NT_TEST_OBJECT(instance);
  ck_assert_ptr_nonnull(self);
}

static void nt_test_object_destroy(NtTypeInstance* instance) {
  NtTestObject* self = NT_TEST_OBJECT(instance);
  ck_assert_ptr_nonnull(self);
}

START_TEST(test_basic) {
  NtTypeInfo info = {};
  info.flags = NT_TYPE_FLAG_STATIC;

  NtType id = nt_type_register(&info);
  ck_assert_uint_gt(id, 0);

  const NtTypeInfo* info_from = nt_type_info_from_type(id);
  ck_assert_ptr_nonnull(info_from);
  ck_assert_uint_eq(info_from->id, id);

  nt_type_unregister(&info);
  ck_assert_uint_eq(info.id, 0);

  info_from = nt_type_info_from_type(id);
  ck_assert_ptr_null(info_from);
}
END_TEST

START_TEST(test_instance) {
  NtType id = nt_test_object_get_type();
  ck_assert_uint_gt(id, 0);

  NtTestObject* obj = NT_TEST_OBJECT(nt_type_instance_new(id, NULL));
  ck_assert_ptr_nonnull(obj);

  NtTestObject* obj2 = NT_TEST_OBJECT(nt_type_instance_ref((NtTypeInstance*)obj));
  ck_assert_ptr_nonnull(obj2);
  ck_assert_uint_eq(obj2->instance.ref_count, 1);

  nt_type_instance_destroy((NtTypeInstance*)obj2);
  ck_assert_uint_eq(obj2->instance.ref_count, 0);
  ck_assert_ptr_eq(obj2, obj);

  // FIXME: why is this not calling "nt_test_object_destroy"?
  nt_type_instance_destroy((NtTypeInstance*)obj);
}
END_TEST

int main(void) {
  Suite* s = suite_create("type");

  TCase* c_basic = tcase_create("basic");
  tcase_add_test(c_basic, test_basic);
  suite_add_tcase(s, c_basic);

  TCase* c_instance = tcase_create("instance");
  tcase_add_test(c_instance, test_instance);
  suite_add_tcase(s, c_instance);

  SRunner* sr = srunner_create(s);
  srunner_set_tap(sr, "-");
  srunner_run_all(sr, CK_VERBOSE);
  int n_failed = srunner_ntests_failed(sr);
  srunner_free(sr);
  return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
