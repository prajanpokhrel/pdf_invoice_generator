import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pdf_inspector.dart';
import '../helpers/sample_invoice.dart';

Future<(InvoicePdf, PdfInspector)> render(
  Invoice invoice,
  InvoiceTemplate template, {
  InvoiceTheme? theme,
}) async {
  final pdf = await InvoiceGenerator.generate(
    invoice,
    template: template,
    theme: theme ?? searchableTheme(),
  );
  return (pdf, PdfInspector(pdf.bytes));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('three built-in templates', () {
    expect(InvoiceTemplate.values.map((t) => t.name), [
      'classic',
      'modern',
      'minimal',
    ]);
    expect(InvoiceTemplate.modern.toString(), 'InvoiceTemplate.modern');
  });

  for (final template in InvoiceTemplate.values) {
    group(template.name, () {
      test('prints all key information on one page', () async {
        final (pdf, inspector) = await render(sampleInvoice(), template);
        final text = inspector.text;
        expect(pdf.pageCount, 1);
        for (final expected in [
          'INV-1001',
          'ABC Technologies',
          'John Doe',
          'Flutter App Development',
          r'$700.00',
          'VAT (13%)',
          r'$711.90',
          'Page 1 of 1',
        ]) {
          expect(text, contains(expected), reason: expected);
        }
      });

      test('multi-page: every item once, header repeated per page', () async {
        final invoice = sampleInvoice(
          items: [
            for (var i = 1; i <= 150; i++)
              InvoiceItem(name: 'Row$i', quantity: 1, unitPrice: 1),
          ],
        );
        final (pdf, inspector) = await render(invoice, template);
        expect(pdf.pageCount, greaterThan(2));
        for (var i = 1; i <= 150; i++) {
          expect(inspector.count('Row$i'), 1, reason: 'Row$i');
        }
        expect(inspector.count('Qty'), pdf.pageCount);
        expect(inspector.count('(continued)'), pdf.pageCount - 1);
      });
    });
  }

  test('templates change the look, never the numbers', () async {
    final results = [
      for (final t in InvoiceTemplate.values) await render(sampleInvoice(), t),
    ];
    final totals = results.map((r) => r.$1.totals.totalInMinorUnits).toSet();
    expect(totals, {71190});
    final sizes = results.map((r) => r.$1.bytes.length).toSet();
    expect(sizes, hasLength(3), reason: 'each template draws differently');
  });

  test('Modern highlights the amount due at the top', () async {
    final (_, modern) = await render(sampleInvoice(), InvoiceTemplate.modern);
    final (_, classic) = await render(sampleInvoice(), InvoiceTemplate.classic);
    expect(modern.text, contains('AMOUNT DUE'));
    expect(modern.count(r'$711.90'), 2); // amount-due card + total row
    expect(classic.count(r'$711.90'), 1);
  });
}
