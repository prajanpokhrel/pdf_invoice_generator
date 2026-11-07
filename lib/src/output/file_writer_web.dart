// Internal: web variant. Browsers have no file system we can write to, so
// this returns null and the caller downloads the file instead.

import 'dart:typed_data';

/// Whether [writePdfFile] can write to a real file system.
const bool canWriteFiles = false;

/// Not supported on the web; always returns `null`.
Future<String?> writePdfFile(
  Uint8List bytes,
  String fileName, {
  String? directory,
}) async =>
    null;
