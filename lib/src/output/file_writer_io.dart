// Internal: Android, iOS, macOS, Windows and Linux variant.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Whether [writePdfFile] can write to a real file system.
const bool canWriteFiles = true;

/// Writes [bytes] to [fileName] inside [directory] (default: the app's
/// documents directory) and returns the full path.
Future<String?> writePdfFile(
  Uint8List bytes,
  String fileName, {
  String? directory,
}) async {
  final dirPath = directory ?? (await getApplicationDocumentsDirectory()).path;
  final dir = Directory(dirPath);
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
