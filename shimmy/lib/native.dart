import 'dart:ffi';
import 'path.dart';

Future<void> init() async {}

DynamicLibrary open() {
  return new DynamicLibrary.open(SHARED_LIB_PATH);
}
