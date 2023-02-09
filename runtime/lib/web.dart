import 'package:web_ffi/web_ffi.dart';
import 'package:web_ffi/web_ffi_modules.dart';
import 'path.dart';

Module? _module;

Future<void> init() async {
  if (_module == null) {
    Memory.init();
    _module = await EmscriptenModule.process('neutron-platform');
  }
}

DynamicLibrary open() {
  Module? m = _module;
  if (m != null) {
    return new DynamicLibrary.fromModule(m);
  }

  throw new StateError('Must call init() before running open() for Neutron Platform')
}
