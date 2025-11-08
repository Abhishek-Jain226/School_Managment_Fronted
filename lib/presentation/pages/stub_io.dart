// Stub file for dart:io when running on web
// This file is never actually used, but provides a stub interface to allow compilation

import 'dart:typed_data';

/// Stub File class for web platform
class File {
  final String path;
  File(this.path);
  Future<Uint8List> readAsBytes() async => throw UnimplementedError();
}

