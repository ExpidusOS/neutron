#include <neutron/platform/user.h>

NT_DEFINE_TYPE(NT, USER, NtUser, nt_user, NT_TYPE_FLAG_DYNAMIC, NT_TYPE_NONE);

static void nt_user_construct(NtTypeInstance* instance, NtTypeArgument* arguments) {}

static void nt_user_destroy(NtTypeInstance* instance) {}
