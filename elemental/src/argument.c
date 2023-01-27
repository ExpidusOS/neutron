#include <neutron/elemental/argument.h>
#include <string.h>

NtValue nt_type_argument_get(NtTypeArgument* arguments, const char* name, NtValue default_value) {
  if (arguments != NULL) {
    for (size_t i = 0; arguments[i].name != NULL; i++) {
      if (strcmp(arguments[i].name, name) == 0) return arguments[i].value;
    }
  }
  return default_value;
}
