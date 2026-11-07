// Internal: picks the file-writing implementation for the platform.
//
// pub.dev treats a package that imports dart:io directly as "not web
// compatible". The conditional export keeps dart:io out of web builds.
export 'file_writer_web.dart' if (dart.library.io) 'file_writer_io.dart';
