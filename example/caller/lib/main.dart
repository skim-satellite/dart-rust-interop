
import 'dart:ffi' as ffi;
import 'dart:io' show Platform, Directory;

import 'package:path/path.dart' as path;

// FFI signature of the Add C function
typedef AddFunc = ffi.Int32 Function(ffi.Int32, ffi.Int32);
// Dart type definition for calling the C foreign function
typedef Add = int Function(int a, int b);

void main() {
  // Open the dynamic library
  var libraryPath =
      path.join(Directory.current.path, 'assets', 'libadder.so');

  if (Platform.isMacOS) {
    libraryPath =
        path.join(Directory.current.path, 'assets', 'libadder.dylib');
  }

  final dylib = ffi.DynamicLibrary.open(libraryPath);

  // Look up the C function 'add'
  final Add add = dylib
      .lookup<ffi.NativeFunction<AddFunc>>('add')
      .asFunction();
  // Call the function
  var result = add(1, 2);
  print("result: ${result}");
}
