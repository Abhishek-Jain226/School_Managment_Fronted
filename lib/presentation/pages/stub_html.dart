// Stub file for dart:html when running on non-web
// This file is never actually used, but provides a stub interface to allow compilation

import 'dart:typed_data';

/// Stub Blob class for non-web platform
class Blob {
  final List<dynamic> data;
  Blob(this.data);
}

/// Stub Url class for non-web platform
class Url {
  static String createObjectUrlFromBlob(Blob blob) => throw UnimplementedError();
  static void revokeObjectUrl(String url) => throw UnimplementedError();
}

/// Stub AnchorElement class for non-web platform
class AnchorElement {
  final String? href;
  AnchorElement({this.href});
  void setAttribute(String name, String value) => throw UnimplementedError();
  void click() => throw UnimplementedError();
}

