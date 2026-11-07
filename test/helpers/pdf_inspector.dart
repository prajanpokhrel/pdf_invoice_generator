import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';

/// A theme using the built-in Helvetica font.
///
/// With a standard (Type 1) font, the PDF stores text as readable strings,
/// so tests can check what was printed. (The bundled TrueType font stores
/// glyph numbers instead, which cannot be searched.)
InvoiceTheme searchableTheme({
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) =>
    InvoiceTheme(
      font: Font.helvetica(),
      boldFont: Font.helveticaBold(),
      pageFormat: pageFormat,
    );

/// Reads a generated PDF for assertions.
final class PdfInspector {
  /// Decompresses every content stream of [bytes].
  PdfInspector(this.bytes) : raw = latin1.decode(bytes) {
    final buffer = StringBuffer();
    for (final m in RegExp(r'(?<!end)stream\r?\n').allMatches(raw)) {
      final end = raw.indexOf('endstream', m.end);
      if (end == -1) continue;
      try {
        buffer.write(latin1.decode(zlib.decode(bytes.sublist(m.end, end))));
      } on FormatException {
        // Not a deflate stream (for example an embedded JPEG): skip.
      }
    }
    content = buffer.toString();
    words = [
      for (final m in RegExp(r'\[\((.*?)\)\]TJ').allMatches(content))
        m.group(1)!.replaceAll(r'\(', '(').replaceAll(r'\)', ')'),
    ];
  }

  /// The PDF file.
  final Uint8List bytes;

  /// The file as text (binary parts are garbled, structure is readable).
  final String raw;

  /// All decompressed page content.
  late final String content;

  /// Every printed word, in drawing order.
  late final List<String> words;

  /// All printed words joined by single spaces.
  String get text => words.join(' ');

  /// How many times [word] was printed as a whole word.
  int count(String word) => words.where((w) => w == word).length;

  /// The first page's MediaBox width and height, in points.
  (double, double) get pageSize {
    final m = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]')
        .firstMatch(raw)!;
    return (double.parse(m.group(1)!), double.parse(m.group(2)!));
  }
}
