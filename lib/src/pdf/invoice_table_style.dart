import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';

/// Overrides for the items table. Every field is optional: `null` keeps
/// the selected template's own look.
///
/// ```dart
/// InvoiceTheme(
///   tableStyle: InvoiceTableStyle(
///     headerColor: PdfColors.grey800,
///     stripeColor: PdfColors.grey100,
///     showBorders: false,
///   ),
/// )
/// ```
@immutable
final class InvoiceTableStyle {
  /// Creates table overrides.
  const InvoiceTableStyle({
    this.headerColor,
    this.headerTextColor,
    this.stripeColor,
    this.borderColor,
    this.showBorders,
    this.rowPadding,
  });

  /// Background of the header row.
  final PdfColor? headerColor;

  /// Text colour of the header row.
  final PdfColor? headerTextColor;

  /// Background of every second row. Use `PdfColors.white` to disable.
  final PdfColor? stripeColor;

  /// Colour of borders and row dividers.
  final PdfColor? borderColor;

  /// `true` draws a full grid, `false` only thin row dividers.
  final bool? showBorders;

  /// Vertical padding inside each row, in points.
  final double? rowPadding;
}
