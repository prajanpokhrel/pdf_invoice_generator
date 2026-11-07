import 'dart:typed_data';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
// ignore: implementation_imports
import 'package:printing/src/interface.dart';

/// A fake printing plugin that records calls instead of opening dialogs.
///
/// It uses `noSuchMethod` instead of overriding `layoutPdf` directly, because
/// that method's parameter list differs between printing 5.14 and 5.15 and
/// this package supports both.
final class FakePrinting
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  /// Every call made to the plugin.
  final List<Invocation> calls = [];

  /// What print/share report (`false` = user cancelled).
  bool result = true;

  /// When set, every call fails with this error.
  Object? error;

  /// The bytes the print dialog received from `onLayout`.
  Uint8List? printedBytes;

  /// Installs a new fake and returns it.
  static FakePrinting install() {
    final fake = FakePrinting();
    PrintingPlatform.instance = fake;
    return fake;
  }

  /// Calls to [method], for example `#sharePdf`.
  List<Invocation> callsTo(Symbol method) =>
      calls.where((c) => c.memberName == method).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    final error = this.error;
    switch (invocation.memberName) {
      case #layoutPdf:
        if (error != null) return Future<bool>.error(error);
        final onLayout = invocation.positionalArguments[1] as LayoutCallback;
        final format = invocation.positionalArguments[3] as PdfPageFormat;
        return Future<Uint8List>.value(onLayout(format)).then((bytes) {
          printedBytes = bytes;
          return result;
        });
      case #sharePdf:
        if (error != null) return Future<bool>.error(error);
        return Future<bool>.value(result);
      case #info:
        return Future<PrintingInfo>.value(PrintingInfo.unavailable);
    }
    return super.noSuchMethod(invocation);
  }
}

/// A fake path_provider returning fixed directories.
final class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  /// Creates a fake whose documents directory is [documents].
  FakePathProvider(this.documents);

  /// The path returned for the documents directory.
  final String documents;

  /// Installs the fake.
  static void install(String documents) =>
      PathProviderPlatform.instance = FakePathProvider(documents);

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;
}
