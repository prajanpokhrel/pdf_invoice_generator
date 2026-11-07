import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:meta/meta.dart';
import 'package:printing/printing.dart';

import '../exceptions/invoice_exceptions.dart';
import '../pdf/invoice_pdf.dart';
import 'file_writer.dart';

/// Where [InvoicePdfActions.save] put the file.
@immutable
final class InvoiceSaveResult {
  /// Created by `save`. Not intended to be called directly.
  @internal
  const InvoiceSaveResult({required this.fileName, this.path});

  /// The file name, for example `INV-1001.pdf`.
  final String fileName;

  /// Full path of the written file, or `null` on the web, where the browser
  /// downloads the file instead.
  final String? path;

  /// Whether the file was handed to the browser as a download (web).
  bool get isDownload => path == null;

  @override
  String toString() => 'InvoiceSaveResult(${path ?? 'download: $fileName'})';
}

/// Print, share and save an already generated [InvoicePdf].
///
/// ```dart
/// final pdf = await InvoiceGenerator.generate(invoice);
/// await pdf.print();
/// await pdf.share();
/// final saved = await pdf.save();
/// ```
///
/// Use these when you already have a PDF (for example from
/// `InvoicePreview.onGenerated`) to avoid generating it twice. The
/// `InvoiceGenerator.print/share/save` shortcuts generate and then call
/// these.
///
/// See the README for exactly what each action does on each platform.
extension InvoicePdfActions on InvoicePdf {
  /// Opens the system print dialog.
  ///
  /// Returns `true` when the document was sent to the printer and `false`
  /// when the user cancelled. On macOS the app needs the
  /// `com.apple.security.print` entitlement.
  Future<bool> print({String? jobName}) => _guard(
        'print',
        () => Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: jobName ?? fileName,
          format: pageFormat,
          // The invoice is already laid out for its page size; do not ask
          // for a re-layout when the user picks other paper.
          dynamicLayout: false,
        ),
      );

  /// Opens the platform's share UI with the PDF attached.
  ///
  /// * Android, iOS, macOS: the system share sheet.
  /// * Windows, Linux: there is no share sheet; the file is opened in the
  ///   default PDF application instead.
  /// * Web: the browser downloads the file.
  ///
  /// [subject], [text] and [emails] pre-fill email apps where supported.
  /// On iPad, pass [sharePositionOrigin] (the button's rectangle) so the
  /// share popover points at it.
  Future<bool> share({
    String? subject,
    String? text,
    List<String>? emails,
    Rect? sharePositionOrigin,
  }) =>
      _guard(
        'share',
        () => Printing.sharePdf(
          bytes: bytes,
          filename: fileName,
          subject: subject,
          body: text,
          emails: emails,
          bounds: sharePositionOrigin,
        ),
      );

  /// Saves the PDF as a file.
  ///
  /// * Android, iOS, macOS, Windows, Linux: writes to [directory], or to the
  ///   app's documents directory (from `path_provider`) when it is `null`.
  ///   An existing file with the same name is replaced.
  /// * Web: the browser downloads the file; [InvoiceSaveResult.path] is
  ///   `null`.
  ///
  /// [fileName] defaults to [InvoicePdf.fileName].
  ///
  /// Note: the app documents directory is private to the app on Android
  /// and, unless file sharing is enabled in Info.plist, on iOS. To let the
  /// user pick a visible location, use [share] instead.
  Future<InvoiceSaveResult> save({String? directory, String? fileName}) {
    final name = fileName ?? this.fileName;
    return _guard('save', () async {
      if (!canWriteFiles) {
        final downloaded =
            await Printing.sharePdf(bytes: bytes, filename: name);
        if (!downloaded) {
          throw const InvoiceOutputException('The browser download failed.');
        }
        return InvoiceSaveResult(fileName: name);
      }
      final path = await writePdfFile(bytes, name, directory: directory);
      return InvoiceSaveResult(fileName: name, path: path);
    });
  }
}

/// Runs a platform action and turns failures into [InvoiceOutputException].
Future<T> _guard<T>(String action, Future<T> Function() run) async {
  try {
    return await run();
  } on InvoiceException {
    rethrow;
  } on MissingPluginException catch (e) {
    throw InvoiceOutputException(
      'Cannot $action: the platform plugin is not available. If you just '
      'added flutter_invoice_generator, stop the app and run it again '
      '(a hot restart does not load new plugins).',
      cause: e,
    );
  } on Object catch (e) {
    throw InvoiceOutputException('Cannot $action the invoice: $e', cause: e);
  }
}
