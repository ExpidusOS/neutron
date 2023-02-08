#include <neutron/platform/linux-platform.h>
#include <neutron/platform/linux-process.h>
#include <neutron/platform/systemd-device-enum.h>
#include <assert.h>
#include <unistd.h>

NT_DEFINE_TYPE(NT, LINUX_PLATFORM, NtLinuxPlatform, nt_linux_platform, NT_TYPE_FLAG_STATIC, NT_TYPE_PLATFORM);

static NtProcess* nt_linux_platform_get_current_process(NtPlatform* platform) {
  return nt_linux_process_new(platform, getpid());
}

static NtDeviceEnum* nt_linux_platform_get_device_enum(NtPlatform* platform) {
  return nt_systemd_device_enum_new();
}

static void nt_linux_platform_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {
  NtPlatform* platform = NT_PLATFORM(instance);
  assert(platform != NULL);

  platform->get_current_process = nt_linux_platform_get_current_process;
  platform->get_device_enum = nt_linux_platform_get_device_enum;
}

static void nt_linux_platform_destroy(NtTypeInstance* instance) {}

NtPlatform* nt_platform_get_global() {
  static NtPlatform* global = NULL;

  if (global == NULL) {
    global = NT_PLATFORM(nt_type_instance_new(NT_TYPE_LINUX_PLATFORM, NULL));
  }

  assert(global != NULL);
  return NT_PLATFORM(nt_type_instance_ref((NtTypeInstance*)global));
}
