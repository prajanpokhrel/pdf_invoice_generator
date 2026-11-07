import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Visual settings for the generated PDF: page size, colours, fonts,
/// sizes and formats.
///
/// The theme is separate from the `Invoice` data, so the same invoice can be
/// rendered in different styles.
///
/// ```dart
/// final theme = InvoiceTheme(
///   primaryColor: PdfColor.fromHex('#16A34A'),
///   pageFormat: PdfPageFormat.letter,
///   dateFormat: 'dd/MM/yyyy',
/// );
/// ```
///
/// ### Fonts
/// By default the package uses its bundled Noto Sans font, which covers
/// Latin, Greek and Cyrillic text and currency symbols such as `$ € £ ₹ ¥`.
/// To print other scripts (for example Devanagari or Arabic), load a font
/// that supports them and pass it as [font], or add it to [fontFallback].
@immutable
final class InvoiceTheme {
  /// Creates a theme. Every value has a sensible default.
  const InvoiceTheme({
    this.pageFormat = PdfPageFormat.a4,
    this.margin = 40,
    this.primaryColor = const PdfColor.fromInt(0xFF2563EB),
    this.secondaryColor = const PdfColor.fromInt(0xFF64748B),
    this.textColor = const PdfColor.fromInt(0xFF0F172A),
    this.baseFontSize = 9.5,
    this.font,
    this.boldFont,
    this.fontFallback = const [],
    this.locale = 'en_US',
    this.dateFormat = 'MMM d, yyyy',
  });

  /// Page size. Use `PdfPageFormat.a4` (default) or `PdfPageFormat.letter`.
  final PdfPageFormat pageFormat;

  /// Page margin on every side, in PDF points (72 points = 1 inch).
  final double margin;

  /// Accent colour: invoice title, table header, total.
  final PdfColor primaryColor;

  /// Colour for secondary text such as addresses and labels.
  final PdfColor secondaryColor;

  /// Main text colour.
  final PdfColor textColor;

  /// Body text size in points. Headings are scaled from this.
  final double baseFontSize;

  /// Regular font. `null` uses the bundled Noto Sans.
  final pw.Font? font;

  /// Bold font. `null` uses the bundled Noto Sans Bold, or [font] when only
  /// [font] is set.
  final pw.Font? boldFont;

  /// Fonts used for characters missing from [font], for example a
  /// Devanagari font for Nepali text.
  final List<pw.Font> fontFallback;

  /// Locale for number separators and month names, for example `en_US`.
  final String locale;

  /// Date pattern, for example `MMM d, yyyy` (default) or `dd/MM/yyyy`.
  final String dateFormat;

  /// Returns a copy with the given fields replaced.
  InvoiceTheme copyWith({
    PdfPageFormat? pageFormat,
    double? margin,
    PdfColor? primaryColor,
    PdfColor? secondaryColor,
    PdfColor? textColor,
    double? baseFontSize,
    pw.Font? font,
    pw.Font? boldFont,
    List<pw.Font>? fontFallback,
    String? locale,
    String? dateFormat,
  }) {
    return InvoiceTheme(
      pageFormat: pageFormat ?? this.pageFormat,
      margin: margin ?? this.margin,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      textColor: textColor ?? this.textColor,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      font: font ?? this.font,
      boldFont: boldFont ?? this.boldFont,
      fontFallback: fontFallback ?? this.fontFallback,
      locale: locale ?? this.locale,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}
