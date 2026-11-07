// Internal: everything a template needs to draw one invoice.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../calculation/invoice_totals.dart';
import '../formatting/invoice_formatter.dart';
import '../models/invoice.dart';
import 'invoice_labels.dart';
import 'invoice_theme.dart';

/// Read-only bundle of data, totals and style passed to templates.
///
/// Templates never calculate anything themselves; they only read [totals].
final class RenderContext {
  /// Creates a context.
  RenderContext({
    required this.invoice,
    required this.totals,
    required this.theme,
    required this.labels,
    required this.formatter,
    required this.logo,
  });

  /// The invoice data.
  final Invoice invoice;

  /// Pre-calculated totals.
  final InvoiceTotals totals;

  /// Visual settings.
  final InvoiceTheme theme;

  /// Fixed words.
  final InvoiceLabels labels;

  /// Money/date formatting.
  final InvoiceFormatter formatter;

  /// Decoded seller logo, or `null`.
  final pw.ImageProvider? logo;

  /// The seller logo, unless the theme hides it.
  pw.ImageProvider? get visibleLogo => theme.showLogo ? logo : null;

  /// [InvoiceTheme.sectionSpacing] scaled by [factor].
  pw.SizedBox gap([double factor = 1]) =>
      pw.SizedBox(height: theme.sectionSpacing * factor);

  /// A light grey used for table lines.
  PdfColor get lineColor => const PdfColor.fromInt(0xFFCBD5E1);

  /// Whether any item has its own discount (shows the Discount column).
  late final bool showDiscountColumn =
      invoice.items.any((item) => item.discount != null);

  /// Whether any item has its own taxes (shows the Tax column). When all
  /// items use the invoice taxes, the rate is only shown in the summary.
  late final bool showTaxColumn =
      invoice.items.any((item) => item.taxes != null);

  /// Body text.
  pw.TextStyle get body =>
      pw.TextStyle(fontSize: theme.baseFontSize, color: theme.textColor);

  /// Body text in bold.
  pw.TextStyle get bold => body.copyWith(fontWeight: pw.FontWeight.bold);

  /// Smaller, lighter text for addresses and captions.
  pw.TextStyle get muted => body.copyWith(
        fontSize: theme.baseFontSize * 0.9,
        color: theme.secondaryColor,
      );

  /// Small upper-case section headings such as "BILL TO".
  pw.TextStyle get caption => body.copyWith(
        fontSize: theme.baseFontSize * 0.8,
        color: theme.secondaryColor,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.8,
      );

  /// A light tint of the primary colour, for backgrounds.
  ///
  /// Mixed with white into a solid colour: PDF fills ignore the alpha
  /// channel of a colour, so a transparent colour would print at full
  /// strength.
  PdfColor get primaryTint => tint(theme.primaryColor, 0.1);

  /// [color] mixed with white; [amount] 0 is white, 1 is [color].
  static PdfColor tint(PdfColor color, double amount) => PdfColor(
        1 - (1 - color.red) * amount,
        1 - (1 - color.green) * amount,
        1 - (1 - color.blue) * amount,
      );
}
