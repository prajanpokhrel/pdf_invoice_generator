import 'dart:typed_data';

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/pdf_inspector.dart';
import '../helpers/sample_invoice.dart';

/// 0x33/255 = 0.2, 0x66/255 = 0.4, 0x99/255 = 0.6: prints as "0.2 0.4 0.6".
const probeColor = PdfColor.fromInt(0xFF336699);
const probeFill = '0.2 0.4 0.6 rg';

Future<PdfInspector> inspect(
  Invoice invoice, {
  InvoiceTheme? theme,
  InvoiceTemplate template = InvoiceTemplate.classic,
}) async {
  final pdf = await InvoiceGenerator.generate(
    invoice,
    template: template,
    theme: theme ?? searchableTheme(),
  );
  return PdfInspector(pdf.bytes);
}

Invoice longInvoice() => sampleInvoice(
      items: [
        for (var i = 0; i < 80; i++)
          InvoiceItem(name: 'Row$i', quantity: 1, unitPrice: 1),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvoiceTheme', () {
    for (final template in InvoiceTemplate.values) {
      test('primaryColor is used by ${template.name}', () async {
        final pdf = await inspect(
          sampleInvoice(),
          template: template,
          theme: searchableTheme().copyWith(primaryColor: probeColor),
        );
        expect(pdf.content, contains(probeFill));
      });
    }

    test('tableStyle overrides the template header colour', () async {
      final pdf = await inspect(
        sampleInvoice(),
        theme: searchableTheme().copyWith(
          tableStyle: const InvoiceTableStyle(headerColor: probeColor),
        ),
      );
      expect(pdf.content, contains(probeFill));
    });

    test('showPageNumbers: false hides "Page X of Y"', () async {
      final pdf = await inspect(
        sampleInvoice(),
        theme: searchableTheme().copyWith(showPageNumbers: false),
      );
      expect(pdf.text, isNot(contains('Page 1 of 1')));
    });

    test('footerText replaces the seller name in the footer', () async {
      final pdf = await inspect(
        longInvoice(),
        theme: searchableTheme().copyWith(footerText: 'Confidential'),
      );
      final pages = pdf.count('Qty'); // one table header per page
      expect(pdf.count('Confidential'), pages);
    });

    test('showContinuationHeader: false', () async {
      final shown = await inspect(longInvoice());
      final hidden = await inspect(
        longInvoice(),
        theme: searchableTheme().copyWith(showContinuationHeader: false),
      );
      expect(shown.count('(continued)'), greaterThan(0));
      expect(hidden.count('(continued)'), 0);
    });

    test('showLogo: false leaves the logo out', () async {
      final png = img.encodePng(img.Image(width: 20, height: 10));
      final invoice = sampleInvoice().copyWith(
        seller: Business(
          name: 'ABC',
          logo: InvoiceLogo.memory(Uint8List.fromList(png)),
        ),
      );
      final imageTag = RegExp(r'/Subtype\s*/Image');
      expect((await inspect(invoice)).raw, matches(imageTag));
      expect(
        (await inspect(
          invoice,
          theme: searchableTheme().copyWith(showLogo: false),
        ))
            .raw,
        isNot(matches(imageTag)),
      );
    });

    test('copyWith keeps every other field', () {
      const theme = InvoiceTheme(borderRadius: 12, sectionSpacing: 20);
      final copy = theme.copyWith(locale: 'de_DE');
      expect(copy.borderRadius, 12);
      expect(copy.sectionSpacing, 20);
      expect(copy.locale, 'de_DE');
      expect(copy.pageFormat, PdfPageFormat.a4);
    });
  });

  group('QR code', () {
    test('payment QR prints its default caption', () async {
      final invoice = sampleInvoice().copyWith(
        qrCode: const InvoiceQrCode.payment('https://pay.example.com/1'),
      );
      expect((await inspect(invoice)).text, contains('Scan to pay'));
    });

    test('invoice URL QR and custom caption', () async {
      final view = sampleInvoice().copyWith(
        qrCode: const InvoiceQrCode.invoiceUrl('https://example.com/i/1'),
      );
      expect((await inspect(view)).text, contains('Scan to view online'));

      final custom = sampleInvoice().copyWith(
        qrCode: const InvoiceQrCode(data: 'hello', caption: 'Our website'),
      );
      expect((await inspect(custom)).text, contains('Our website'));
    });

    test('no QR, no caption', () async {
      expect((await inspect(sampleInvoice())).text, isNot(contains('Scan')));
    });

    test('QR is drawn in every template', () async {
      for (final template in InvoiceTemplate.values) {
        final without = await inspect(sampleInvoice(), template: template);
        final withQr = await inspect(
          sampleInvoice().copyWith(
            qrCode: const InvoiceQrCode.payment('https://pay.example.com/1'),
          ),
          template: template,
        );
        // A QR code is many filled squares: lots of extra drawing commands.
        expect(
          withQr.content.length,
          greaterThan(without.content.length + 1000),
          reason: template.name,
        );
      }
    });

    test('invalid QR data is a validation error', () async {
      for (final data in ['', 'x' * 5000]) {
        await expectLater(
          InvoiceGenerator.generate(
            sampleInvoice().copyWith(qrCode: InvoiceQrCode(data: data)),
          ),
          throwsA(
            isA<InvoiceValidationException>().having(
              (e) => e.issues.single.field,
              'field',
              'qrCode.data',
            ),
          ),
        );
      }
    });
  });
}
