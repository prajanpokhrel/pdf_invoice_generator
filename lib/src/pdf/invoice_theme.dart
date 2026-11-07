import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/equality.dart';
import 'invoice_table_style.dart';

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
///   borderRadius: 8,
///   tableStyle: InvoiceTableStyle(stripeColor: PdfColors.grey100),
/// );
/// ```
///
/// Every template reads the same theme, so colours, fonts and spacing carry
/// over when you switch templates.
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
    this.sectionSpacing = 14,
    this.borderRadius = 6,
    this.tableStyle = const InvoiceTableStyle(),
    this.showLogo = true,
    this.showPageNumbers = true,
    this.showContinuationHeader = true,
    this.footerText,
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

  /// Vertical space between sections, in points. Smaller values fit more
  /// on a page.
  final double sectionSpacing;

  /// Corner radius for boxes in templates that use rounded shapes
  /// (Modern). `0` gives square corners.
  final double borderRadius;

  /// Overrides for the items table.
  final InvoiceTableStyle tableStyle;

  /// Whether to print the seller logo, when one is set.
  final bool showLogo;

  /// Whether to print "Page X of Y" in the footer.
  final bool showPageNumbers;

  /// Whether pages 2+ start with a small "INVOICE INV-1001 (continued)" line.
  final bool showContinuationHeader;

  /// Text on the left of every page footer. `null` prints the seller name;
  /// an empty string prints nothing.
  final String? footerText;

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
    double? sectionSpacing,
    double? borderRadius,
    InvoiceTableStyle? tableStyle,
    bool? showLogo,
    bool? showPageNumbers,
    bool? showContinuationHeader,
    String? footerText,
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
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      borderRadius: borderRadius ?? this.borderRadius,
      tableStyle: tableStyle ?? this.tableStyle,
      showLogo: showLogo ?? this.showLogo,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      showContinuationHeader:
          showContinuationHeader ?? this.showContinuationHeader,
      footerText: footerText ?? this.footerText,
    );
  }

  /// Fonts are compared by identity: reuse the same `Font` objects to keep
  /// two themes equal.
  @override
  bool operator ==(Object other) =>
      other is InvoiceTheme &&
      other.pageFormat == pageFormat &&
      other.margin == margin &&
      other.primaryColor == primaryColor &&
      other.secondaryColor == secondaryColor &&
      other.textColor == textColor &&
      other.baseFontSize == baseFontSize &&
      other.font == font &&
      other.boldFont == boldFont &&
      listEquals(other.fontFallback, fontFallback) &&
      other.locale == locale &&
      other.dateFormat == dateFormat &&
      other.sectionSpacing == sectionSpacing &&
      other.borderRadius == borderRadius &&
      other.tableStyle == tableStyle &&
      other.showLogo == showLogo &&
      other.showPageNumbers == showPageNumbers &&
      other.showContinuationHeader == showContinuationHeader &&
      other.footerText == footerText;

  @override
  int get hashCode => Object.hashAll([
        pageFormat,
        margin,
        primaryColor,
        secondaryColor,
        textColor,
        baseFontSize,
        font,
        boldFont,
        Object.hashAll(fontFallback),
        locale,
        dateFormat,
        sectionSpacing,
        borderRadius,
        tableStyle,
        showLogo,
        showPageNumbers,
        showContinuationHeader,
        footerText,
      ]);
}
