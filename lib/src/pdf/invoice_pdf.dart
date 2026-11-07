import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';

import '../calculation/invoice_totals.dart';

/// A generated invoice PDF.
///
/// ```dart
/// final pdf = await InvoiceGenerator.generate(invoice);
/// pdf.bytes;     // upload, email, or write to a file
/// pdf.fileName;  // 'INV-1001.pdf'
/// pdf.pageCount; // 1
/// pdf.totals;    // the amounts printed on the PDF
/// ```
@immutable
final class InvoicePdf {
  /// Created by `InvoiceGenerator`. Not intended to be called directly.
  @internal
  const InvoicePdf({
    required this.bytes,
    required this.fileName,
    required this.pageCount,
    required this.totals,
    this.pageFormat = PdfPageFormat.a4,
  });

  /// The PDF file contents.
  final Uint8List bytes;

  /// Suggested file name, derived from the invoice number, for example
  /// `INV-1001.pdf`. Characters that are unsafe in file names are replaced
  /// with `_`.
  final String fileName;

  /// Number of pages in the document.
  final int pageCount;

  /// The calculated totals printed on this PDF.
  final InvoiceTotals totals;

  /// The page size the PDF was laid out for.
  final PdfPageFormat pageFormat;

  @override
  String toString() =>
      'InvoicePdf($fileName, $pageCount pages, ${bytes.length} bytes)';
}
