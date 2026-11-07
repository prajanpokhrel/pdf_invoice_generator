import 'dart:async';

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pdf_inspector.dart';
import '../helpers/sample_invoice.dart';

List<InvoiceItem> items(int count) => [
      for (var i = 1; i <= count; i++)
        InvoiceItem(name: 'Item$i', quantity: 1, unitPrice: 10),
    ];

/// Runs [body] and returns every line it printed (the pdf library reports
/// missing glyphs with `print`).
Future<List<String>> capturePrints(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('output', () {
    test('is a valid PDF file with metadata', () async {
      final pdf = await InvoiceGenerator.generate(sampleInvoice());
      final inspector = PdfInspector(pdf.bytes);
      expect(inspector.raw, startsWith('%PDF-'));
      expect(inspector.raw.trimRight(), endsWith('%%EOF'));
      expect(pdf.pageCount, 1);
      expect(pdf.fileName, 'INV-1001.pdf');
      expect(pdf.totals.total, 711.9);
      expect(inspector.raw, contains('flutter_invoice_generator'));
    });

    test('prints the invoice data and the calculated totals', () async {
      final pdf = await InvoiceGenerator.generate(
        sampleInvoice(),
        theme: searchableTheme(),
      );
      final text = PdfInspector(pdf.bytes).text;
      for (final expected in [
        'INVOICE',
        'INV-1001',
        'Nov 7, 2026', // issue date
        'Dec 7, 2026', // due date
        'ABC Technologies',
        'John Doe',
        'Lalitpur, Nepal',
        'Flutter App Development',
        r'$500.00',
        r'$700.00', // subtotal
        r'-$70.00', // discount
        'Discount (10%)',
        'VAT (13%)',
        r'$81.90',
        r'$711.90', // total
        'Page 1 of 1',
        'Thank you for your business!',
      ]) {
        expect(text, contains(expected), reason: expected);
      }
    });

    test('discount and tax columns appear only when items need them', () async {
      Future<String> textOf(Invoice invoice) async => PdfInspector(
            (await InvoiceGenerator.generate(
              invoice,
              theme: searchableTheme(),
            ))
                .bytes,
          ).text;

      final plain = await textOf(sampleInvoice());
      expect(plain, isNot(contains('Exempt')));
      expect(plain.split(' ').where((w) => w == 'Tax'), isEmpty);

      final mixed = await textOf(
        sampleInvoice(
          items: [
            InvoiceItem(
              name: 'A',
              quantity: 1,
              unitPrice: 100,
              discount: const Discount.percentage(5),
            ),
            InvoiceItem(name: 'B', quantity: 1, unitPrice: 50, taxes: const []),
          ],
        ),
      );
      expect(mixed, contains('Exempt'));
      expect(mixed, contains('Tax'));
      expect(mixed, contains('5%'));
    });

    test('optional sections are printed only when set', () async {
      final invoice = sampleInvoice().copyWith(
        notes: 'Pay soon please',
        paymentInformation: const PaymentInformation(
          bankName: 'Nabil Bank',
          iban: 'NP00TEST',
        ),
        details: const [InvoiceDetail(label: 'PO', value: 'PO-7781')],
      );
      final text = PdfInspector(
        (await InvoiceGenerator.generate(invoice, theme: searchableTheme()))
            .bytes,
      ).text;
      expect(text, contains('Pay soon please'));
      expect(text, contains('Nabil Bank'));
      expect(text, contains('NP00TEST'));
      expect(text, contains('PO-7781'));
      expect(text, isNot(contains('SWIFT')));

      final bare = PdfInspector(
        (await InvoiceGenerator.generate(
          sampleInvoice(),
          theme: searchableTheme(),
        ))
            .bytes,
      ).text;
      expect(bare, isNot(contains('NOTES')));
      expect(bare, isNot(contains('PAYMENT')));
    });

    test('labels can be translated or hidden', () async {
      final pdf = await InvoiceGenerator.generate(
        sampleInvoice(),
        theme: searchableTheme(),
        labels: const InvoiceLabels(
          invoiceTitle: 'FACTURE',
          total: 'Montant',
          thankYou: null,
          pageOf: '{page}/{pages}',
        ),
      );
      final text = PdfInspector(pdf.bytes).text;
      expect(text, contains('FACTURE'));
      expect(text, contains('Montant'));
      expect(text, contains('1/1'));
      expect(text, isNot(contains('Thank')));
    });

    test('unsafe characters are removed from the file name', () {
      expect(InvoiceGenerator.fileNameFor('INV/2026 #1'), 'INV_2026__1.pdf');
      expect(InvoiceGenerator.fileNameFor('  '), 'invoice.pdf');
    });
  });

  group('page formats', () {
    test('A4 is the default', () async {
      final pdf = await InvoiceGenerator.generate(sampleInvoice());
      final (w, h) = PdfInspector(pdf.bytes).pageSize;
      expect(w, closeTo(595.28, 0.01));
      expect(h, closeTo(841.89, 0.01));
    });

    test('Letter', () async {
      final pdf = await InvoiceGenerator.generate(
        sampleInvoice(),
        theme: const InvoiceTheme(pageFormat: PdfPageFormat.letter),
      );
      final (w, h) = PdfInspector(pdf.bytes).pageSize;
      expect(w, 612);
      expect(h, 792);
    });
  });

  group('multiple pages', () {
    final pageCounts = <int, int>{};

    for (final count in [1, 10, 50, 150]) {
      test('$count items: table continues with a repeated header', () async {
        final invoice = sampleInvoice(items: items(count));
        final pdf =
            await InvoiceGenerator.generate(invoice, theme: searchableTheme());
        final inspector = PdfInspector(pdf.bytes);
        pageCounts[count] = pdf.pageCount;

        // Every item is printed exactly once.
        for (var i = 1; i <= count; i++) {
          expect(inspector.count('Item$i'), 1, reason: 'Item$i');
        }
        // The table header ('Qty') is repeated on every page.
        expect(inspector.count('Qty'), pdf.pageCount);
        // Every page has a page number, and the last one is correct.
        expect(
          inspector.text,
          contains('Page ${pdf.pageCount} of ${pdf.pageCount}'),
        );
        // The total is printed once, after the last item.
        // count x 10.00, -10% = 9.00 each, +13% VAT. Computed in whole
        // cents: doing it with doubles (count * 10 * 0.9 * 1.13) would give
        // 10.169999999999998 - the exact bug this package prevents.
        expect(pdf.totals.totalInMinorUnits, count * 900 * 113 ~/ 100);
        // Pages 2+ have the "continued" header; page 1 does not.
        expect(inspector.count('(continued)'), pdf.pageCount - 1);
      });
    }

    test('page count grows with the number of items', () {
      expect(pageCounts[1], 1);
      expect(pageCounts[10], 1);
      expect(pageCounts[50], greaterThan(1));
      expect(pageCounts[150], greaterThan(pageCounts[50]!));
    });

    test('1000 items do not hit a page limit', () async {
      final pdf = await InvoiceGenerator.generate(
        sampleInvoice(items: items(1000)),
      );
      expect(pdf.pageCount, greaterThan(20)); // pdf's default limit is 20
      expect(pdf.totals.lines, hasLength(1000));
    });
  });

  group('currencies and fonts', () {
    for (final currency in Currency.values) {
      test('${currency.code}: every symbol renders with the bundled font',
          () async {
        late InvoicePdf pdf;
        final printed = await capturePrints(() async {
          pdf = await InvoiceGenerator.generate(
            sampleInvoice(currency: currency),
          );
        });
        expect(
          printed.where((l) => l.contains('Unable to find a font')),
          isEmpty,
        );
        expect(pdf.pageCount, 1);
      });
    }

    test('the glyph check really detects missing symbols', () async {
      // Helvetica has no Rupee sign, so the pdf library must complain.
      final printed = await capturePrints(() async {
        await InvoiceGenerator.generate(
          sampleInvoice(currency: Currency.inr),
          theme: searchableTheme(),
        );
      });
      expect(printed.any((l) => l.contains('Unable to find a font')), isTrue);
    });

    test('JPY amounts have no decimals', () async {
      final pdf = await InvoiceGenerator.generate(
        sampleInvoice(currency: Currency.jpy),
        theme: searchableTheme(),
      );
      // 700 - 10% = 630, + 13% = 81.9 -> 82 yen, total 712.
      expect(pdf.totals.total, 712);
    });

    test('symbol after the amount', () async {
      const sek = Currency(
        code: 'SEK',
        symbol: 'kr',
        symbolBeforeAmount: false,
        spaceBetweenSymbolAndAmount: true,
      );
      final text = PdfInspector(
        (await InvoiceGenerator.generate(
          sampleInvoice(currency: sek),
          theme: searchableTheme(),
        ))
            .bytes,
      ).text;
      expect(text, contains('711.90 kr'));
    });
  });

  group('errors', () {
    test('invalid data throws InvoiceValidationException', () async {
      await expectLater(
        InvoiceGenerator.generate(sampleInvoice(items: const [])),
        throwsA(isA<InvoiceValidationException>()),
      );
    });

    test('unknown locale throws a helpful InvoiceGenerationException',
        () async {
      await expectLater(
        InvoiceGenerator.generate(
          sampleInvoice(),
          theme: const InvoiceTheme(locale: 'xx_YY'),
        ),
        throwsA(
          isA<InvoiceGenerationException>().having(
            (e) => e.message,
            'message',
            contains('not supported'),
          ),
        ),
      );
    });

    test('locale without loaded date data explains the fix', () async {
      await expectLater(
        InvoiceGenerator.generate(
          sampleInvoice(),
          theme: const InvoiceTheme(locale: 'fr_FR'),
        ),
        throwsA(
          isA<InvoiceGenerationException>().having(
            (e) => e.message,
            'message',
            contains('initializeDateFormatting'),
          ),
        ),
      );
    });

    test('custom date format', () async {
      final text = PdfInspector(
        (await InvoiceGenerator.generate(
          sampleInvoice(),
          theme: searchableTheme().copyWith(dateFormat: 'dd/MM/yyyy'),
        ))
            .bytes,
      ).text;
      expect(text, contains('07/11/2026'));
    });
  });
}
