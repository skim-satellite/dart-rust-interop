# dart-rust-interop

A brief workflow for Dart/Rust interop.

<br/>

## References

- Rust side
  - https://github.com/eqrion/cbindgen/blob/master/docs.md
- Dart side
  - https://dart.dev/guides/libraries/c-interop#interfacing-with-native-types
  - https://docs.flutter.dev/development/packages-and-plugins/developing-packages
  - https://pub.dev/packages/ffigen
  - https://github.com/dart-lang/ffigen/tree/master/lib/src
  - https://github.com/dart-lang/samples/blob/master/ffi/primitives/primitives.dart
- Articles
  - https://dev.to/sunshine-chain/dart-meets-rust-a-match-made-in-heaven-9f5

<br/>

## Structure

The example directories has 2 sub directories:
- **caller** is the dart project that loads and uses a dynamic library created from the adder.
- **adder** is the rust project that creates the dynamic librari files.

<br/>

## Install toolchain and utilities

```sh
$ cargo install cbindgen

# In case of M1 mac
$ rustup toolchain install nightly-aarch64-apple-darwin
$ brew install llvm # for OSX
$ sudo apt-get install libclang-dev # for Debian/Ubuntu
```

<br/>

## Create and configure a rust library

```sh
$ mkdir example && cd example

# To create a new rust library
$ cargo new --lib adder --vcs none
$ cd adder

# To add the build dependency
$ cargo add --build cbindgen
```

Update the Cargo.toml
```diff
[package]
name = "adder"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

+[lib]
+crate-type = ["cdylib", "rlib", "staticlib"]

[dependencies]

+[build-dependencies]
+cbindgen = "0.24.3"
```

Update the src/lib.rs:
```diff
#[cfg(test)]
mod tests {

+    use crate::adder;

    #[test]
    fn it_works() {
+        let result = adder::add(2, 2);
        assert_eq!(result, 4);
    }
}

+pub mod adder {
+    #[no_mangle] 
+    pub extern "C" fn add(a: i32, b: i32) -> i32 {
+        a + b
+    }
+}
```

Run a test to confirm the updates:
```sh
$ cargo test
```

<br/>

## Run cbindgen

First, create the cbindgen.toml (scratched from Warp):
```toml
language = "C"

cpp_compat = true
include_guard = "_ADDER_H_"

[parse]
parse_deps = false
clean = false

[parse.expand]
crates = ["adder"]
```

Build library files and create header file:
```sh
$ rustup run nightly -- cbindgen -c cbindgen.toml -o adder.h
$ cargo build
```

<br/>

## Create and configure a dart project

```sh
# Back to the example directory
$ cd .. 

# Create a new dart project
$ flutter create --template=package caller
$ cd caller

# Add dependencies and get packages
$ dart pub add -d ffigen
$ dart pub add ffi
$ dart pub get
```

The pubspec.yaml file looks like this:
```yaml
name: caller
description: A new Flutter package project.
version: 0.0.1
homepage:

environment:
  sdk: ">=2.17.6 <3.0.0"
  flutter: ">=1.17.0"

dependencies:
  ffi: ^2.0.1
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  ffigen: ^6.0.1

flutter:

# This is important to point wehre the library is
ffigen:
  name: NativeLibrary
  description: Bindings to `../adder/adder.h`.
  output: 'generated_bindings.dart'
  headers:
    entry-points:
      - '../adder/adder.h'
```

Don't forget to copy the library files into a directory:
```sh
$ mkdir assets # example/caller/assets
$ cp ../adder/target/debug/libadder.* ./assets
```

Execute the ffigen to generate a wrapping dart file:
```sh
$ dart run ffigen
```

Create a dart file as the entry point:
```sh
$ touch lib/main.dart
```

For the new dart file:
```dart
// Scratched from https://github.com/dart-lang/samples/blob/master/ffi/hello_world/hello.dart

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
```

Finally run the dart file:
```sh
$ dart run lib/main.dart
```

<br/>

## For Warp and Warp-dart

The path of the repos:
- Warp should be located under $HOME/$REPOS/Rust.
- Warp-Dart should be located under $HOME/$REPOS.
- This is because the build.rs of Warp specifies the path.

We use the nightly version of Rust. To regenerate the warp.h file:
```sh
$ cd $WARP_REPO
$ rustup nightly
$ rustup default nightly
$ cargo clean 
$ cargo build --features build-header # see the build.rs file
```

LLVM is required for Dart ffigen. To regenerate the warp_dart_bindings_generated.dart:
```sh
$ cd $WARP_DART_REPO
$ dart run ffigen --config ffigen.yaml # see the yaml file
``` 

The ffigen.yaml file should be changed to specify the path of LLVM (libclang.so) depends on the OS (Win, Mac, or Linux).


