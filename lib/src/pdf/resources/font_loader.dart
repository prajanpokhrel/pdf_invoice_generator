// Internal: loads the fonts used to render the PDF.

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../exceptions/invoice_exceptions.dart';
import '../invoice_theme.dart';

const _assetDir = 'packages/flutter_invoice_generator/assets/fonts';

/// Raw bytes of the bundled fonts, kept after the first successful load.
///
/// This cache holds immutable, read-only resources, never user data. A fresh
/// `pw.Font` is created for every document from these bytes.
final Map<String, ByteData> _bundledFontCache = {};

Future<ByteData> _loadBundled(String fileName) async {
  final cached = _bundledFontCache[fileName];
  if (cached != null) return cached;
  try {
    return _bundledFontCache[fileName] =
        await rootBundle.load('$_assetDir/$fileName');
  } on Object catch (e) {
    throw InvoiceGenerationException(
      'Could not load the bundled font "$fileName". Make sure Flutter '
      'bindings are initialised (WidgetsFlutterBinding.ensureInitialized()) '
      'or pass your own font with InvoiceTheme(font: ...).',
      cause: e,
    );
  }
}

/// Builds the PDF text theme: the theme's fonts, or the bundled Noto Sans.
Future<pw.ThemeData> resolveFontTheme(InvoiceTheme theme) async {
  final base =
      theme.font ?? pw.Font.ttf(await _loadBundled('NotoSans-Regular.ttf'));
  final bold = theme.boldFont ??
      (theme.font ?? pw.Font.ttf(await _loadBundled('NotoSans-Bold.ttf')));
  return pw.ThemeData.withFont(
    base: base,
    bold: bold,
    fontFallback: theme.fontFallback,
  );
}
