import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

// Value equality lets InvoicePreview skip regenerating when a parent widget
// rebuilds with new-but-identical settings.
void main() {
  test('InvoiceTheme compares by value', () {
    final a = InvoiceTheme(primaryColor: PdfColor.fromHex('#16A34A'));
    final b = InvoiceTheme(primaryColor: PdfColor.fromHex('#16A34A'));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(a.copyWith(borderRadius: 0)));
    expect(a, isNot(a.copyWith(pageFormat: PdfPageFormat.letter)));
  });

  test('InvoiceTheme compares fonts by identity', () {
    final font = Font.helvetica();
    expect(
      InvoiceTheme(font: font, fontFallback: [font]),
      InvoiceTheme(font: font, fontFallback: [font]),
    );
    expect(
      InvoiceTheme(font: Font.helvetica()),
      isNot(InvoiceTheme(font: Font.helvetica())),
    );
  });

  test('InvoiceTableStyle compares by value', () {
    const a = InvoiceTableStyle(showBorders: false, rowPadding: 6);
    const b = InvoiceTableStyle(showBorders: false, rowPadding: 6);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const InvoiceTableStyle(showBorders: true)));
    expect(
      const InvoiceTheme(tableStyle: a),
      const InvoiceTheme(tableStyle: b),
    );
  });

  test('InvoiceLabels compares by value', () {
    expect(const InvoiceLabels(), const InvoiceLabels());
    expect(
      const InvoiceLabels().hashCode,
      const InvoiceLabels().hashCode,
    );
    expect(
      const InvoiceLabels(),
      isNot(const InvoiceLabels(invoiceTitle: 'FACTURE')),
    );
    expect(
      const InvoiceLabels(),
      isNot(const InvoiceLabels(thankYou: null)),
    );
  });
}
