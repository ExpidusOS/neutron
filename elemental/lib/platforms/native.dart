import 'dart:ffi';

import 'native/bindings.dart' as bindings;
import 'native/path.dart';

final NeutronElemental = bindings.NeutronElemental(
    DynamicLibrary.open(NEUTRON_ELEMENTAL_SHARED_LIB_PATH));
