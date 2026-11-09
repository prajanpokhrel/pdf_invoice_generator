// Long text must never freeze or crash generation.
//
// Background: the pdf library keeps adding pages when a block that cannot be
// split is taller than a page; only a debug-mode assert stops it. In release
// builds that would hang the app. These tests make sure long user input
// either flows across pages or fails fast with a clear message.

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_invoice_generator/src/pdf/sections/items_table.dart'
    show descriptionChunks, maxDescriptionChunk, maxDescriptionChunkLines;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pdf_inspector.dart';
import '../helpers/sample_invoice.dart';

/// [count] sentences, each ending with a numbered marker word, so tests can
/// check that every part was printed exactly once.
String longText(String marker, int count) => [
      for (var i = 0; i < count; i++)
        'Lorem ipsum dolor sit amet consectetur adipiscing $marker$i.',
    ].join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final template in InvoiceTemplate.values) {
    group(template.name, () {
      Future<(InvoicePdf, PdfInspector)> render(Invoice invoice) async {
        final pdf = await InvoiceGenerator.generate(
          invoice,
          template: template,
          theme: searchableTheme(),
        );
        return (pdf, PdfInspector(pdf.bytes));
      }

      test('very long terms flow over several pages', () async {
        final (pdf, inspector) = await render(
          sampleInvoice().copyWith(terms: longText('T', 400)),
        );
        expect(pdf.pageCount, greaterThan(2));
        for (var i = 0; i < 400; i += 37) {
          expect(inspector.count('T$i.'), 1, reason: 'T$i');
        }
        expect(inspector.text, contains('Thank you for your business!'));
      });

      test('long notes and payment instructions flow too', () async {
        final (pdf, inspector) = await render(
          sampleInvoice().copyWith(
            notes: longText('N', 200),
            paymentInformation: PaymentInformation(
              bankName: 'Nabil Bank',
              instructions: longText('P', 200),
            ),
          ),
        );
        expect(pdf.pageCount, greaterThan(1));
        expect(inspector.count('N199.'), 1);
        expect(inspector.count('P199.'), 1);
      });

      test('a 12,000-character item description continues in extra rows',
          () async {
        final (pdf, inspector) = await render(
          sampleInvoice(
            items: [
              InvoiceItem(
                name: 'Big',
                description: longText('D', 200),
                quantity: 1,
                unitPrice: 10,
              ),
              InvoiceItem(name: 'After', quantity: 1, unitPrice: 5),
            ],
          ),
        );
        expect(pdf.pageCount, greaterThan(2));
        for (var i = 0; i < 200; i++) {
          expect(inspector.count('D$i.'), 1, reason: 'D$i');
        }
        expect(inspector.count('After'), 1);
        // The table header still repeats on every page with the table.
        expect(inspector.count('Qty'), greaterThanOrEqualTo(2));
      });

      test('content that can never fit fails fast with a clear message',
          () async {
        final address = List.generate(90, (i) => 'Line $i').join('\n');
        await expectLater(
          InvoiceGenerator.generate(
            sampleInvoice().copyWith(
              customer: Customer(name: 'C', address: address),
            ),
            template: template,
          ),
          throwsA(
            isA<InvoiceGenerationException>().having(
              (e) => e.message,
              'message',
              contains('taller than one page'),
            ),
          ),
        );
      });
    });
  }

  group('descriptionChunks', () {
    List<String> words(String s) =>
        s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    test('empty and short descriptions', () {
      expect(descriptionChunks(null), isEmpty);
      expect(descriptionChunks('   '), isEmpty);
      expect(descriptionChunks('iOS + Android'), ['iOS + Android']);
      expect(descriptionChunks('line 1\nline 2'), ['line 1\nline 2']);
    });

    test('long text: every chunk is small and no word is lost', () {
      final text = longText('W', 300);
      final chunks = descriptionChunks(text);
      expect(chunks.length, greaterThan(10));
      for (final c in chunks) {
        expect(c.length, lessThanOrEqualTo(maxDescriptionChunk));
      }
      expect(words(chunks.join(' ')), words(text));
    });

    test('many short lines are split by line count', () {
      final text = List.generate(30, (i) => 'row $i').join('\n');
      final chunks = descriptionChunks(text);
      for (final c in chunks) {
        expect(
          '\n'.allMatches(c).length,
          lessThan(maxDescriptionChunkLines),
        );
      }
      expect(words(chunks.join('\n')), words(text));
    });

    test('a single very long word is cut into pieces', () {
      final chunks = descriptionChunks('x' * 1000);
      expect(chunks.join(), 'x' * 1000);
      expect(chunks.every((c) => c.length <= maxDescriptionChunk), isTrue);
    });

    test('no leading space after a line break', () {
      expect(descriptionChunks('a\nb').single, 'a\nb');
    });
  });
}
