#include <neutron/packages/manager.h>
#include <assert.h>

NT_DEFINE_TYPE(NT, PACKAGE_MANAGER, NtPackageManager, nt_package_manager, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_package_manager_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
}

static void nt_package_manager_destroy(NtTypeInstance* instance) {
}

NtList* nt_package_manager_list(NtPackageManager* self, NtPackageLocation loc, NtBacktrace* bt, NtError** error) {
  assert(NT_IS_PACKAGE_MANAGER(self));
  assert(NT_IS_BACKTRACE(bt));
  assert(error != NULL && *error == NULL);
  assert(self->list != NULL);
  return self->list(self, loc, bt, error);
}

NtPackage* nt_package_manager_install(NtPackageManager* self, const char* path, NtPackageLocation loc, NtBacktrace* bt, NtError** error) {
  assert(NT_IS_PACKAGE_MANAGER(self));
  assert(path != NULL);
  assert(error != NULL && *error == NULL);
  assert(self->install != NULL);

  nt_backtrace_push(bt, nt_package_manager_install);

  // TODO: we need to check if path is a compressed file
  // TODO: we also need to check permissions
  // TODO: we also also need to extract the compressed package to a temp directory
  NtPackage* pkg = nt_package_new(path);
  if (pkg == NULL) {
    *error = nt_error_new("Failed to open package", bt);
    nt_backtrace_pop(bt);
    return NULL;
  }

  if (!self->install(self, pkg, loc, bt, error)) {
    nt_type_instance_unref((NtTypeInstance*)pkg);
    pkg = NULL;
  }

  nt_backtrace_pop(bt);
  return pkg;
}

bool nt_package_manager_uninstall(NtPackageManager* self, NtPackage* pkg, NtBacktrace* bt, NtError** error) {
  assert(NT_IS_PACKAGE_MANAGER(self));
  assert(NT_IS_PACKAGE(pkg));
  assert(error != NULL && *error == NULL);
  assert(self->uninstall != NULL);
  return self->uninstall(self, pkg, bt, error);
}
