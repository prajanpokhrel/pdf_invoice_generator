import 'dart:typed_data';

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_invoice_generator/src/pdf/resources/logo_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import '../helpers/sample_invoice.dart';

img.Image solid(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(37, 99, 235));
  return image;
}

Uint8List png(int w, int h) => img.encodePng(solid(w, h));

Matcher throwsImageError([String? contains]) => throwsA(
      isA<InvoiceImageException>().having(
        (e) => e.message,
        'message',
        contains == null ? anything : matches(RegExp(contains)),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeLogo', () {
    test('PNG, JPEG, GIF and BMP are supported', () {
      final source = solid(40, 20);
      for (final bytes in [
        img.encodePng(source),
        img.encodeJpg(source),
        img.encodeGif(source),
        img.encodeBmp(source),
      ]) {
        final logo = decodeLogo(bytes);
        expect(logo.width, 40);
        expect(logo.height, 20);
      }
    });

    test('small JPEGs are embedded without re-encoding', () {
      final logo = decodeLogo(img.encodeJpg(solid(40, 20)));
      expect(logo, isA<pw.MemoryImage>());
    });

    test('large images are scaled down, keeping the aspect ratio', () {
      final wide = decodeLogo(png(3000, 1500));
      expect(wide.width, maxLogoDimension);
      expect(wide.height, maxLogoDimension ~/ 2);

      final tall = decodeLogo(png(500, 2048));
      expect(tall.height, maxLogoDimension);
      expect(tall.width, 250);
    });

    test('empty data', () {
      expect(() => decodeLogo(Uint8List(0)), throwsImageError('empty'));
    });

    test('data that is not an image', () {
      expect(
        () => decodeLogo(Uint8List.fromList(List.filled(64, 7))),
        throwsImageError('not recognised'),
      );
    });

    test('formats without a reliable signature are rejected (TGA)', () {
      expect(
        () => decodeLogo(img.encodeTga(solid(10, 10))),
        throwsImageError('Supported formats'),
      );
    });

    test('truncated PNG', () {
      final bytes = png(100, 100);
      expect(
        () => decodeLogo(Uint8List.sublistView(bytes, 0, 60)),
        throwsA(isA<InvoiceImageException>()),
      );
    });
  });

  group('loadLogo', () {
    test('no logo', () async {
      expect(await loadLogo(null), isNull);
    });

    test('memory', () async {
      final logo = await loadLogo(InvoiceLogo.memory(png(10, 10)));
      expect(logo!.width, 10);
    });

    test('missing asset gives a helpful message', () async {
      await expectLater(
        loadLogo(const InvoiceLogo.asset('assets/does_not_exist.png')),
        throwsImageError('pubspec.yaml'),
      );
    });

    test('network: success', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://example.com/logo.png');
        return http.Response.bytes(png(12, 6), 200);
      });
      final logo = await loadLogo(
        const InvoiceLogo.network('https://example.com/logo.png'),
        httpClient: client,
      );
      expect(logo!.width, 12);
    });

    test('network: HTTP error', () async {
      final client = MockClient((_) async => http.Response('nope', 404));
      await expectLater(
        loadLogo(
          const InvoiceLogo.network('https://example.com/logo.png'),
          httpClient: client,
        ),
        throwsImageError('HTTP 404'),
      );
    });

    test('network: connection failure', () async {
      final client =
          MockClient((_) async => throw http.ClientException('down'));
      await expectLater(
        loadLogo(
          const InvoiceLogo.network('https://example.com/logo.png'),
          httpClient: client,
        ),
        throwsImageError('internet connection'),
      );
    });

    test('network: invalid URL', () async {
      await expectLater(
        loadLogo(const InvoiceLogo.network('not a url')),
        throwsImageError('not a valid URL'),
      );
    });
  });

  group('in a generated PDF', () {
    test('a logo is embedded as an image', () async {
      final invoice = sampleInvoice().copyWith(
        seller: Business(name: 'ABC', logo: InvoiceLogo.memory(png(80, 40))),
      );
      final pdf = await InvoiceGenerator.generate(invoice);
      expect(
        String.fromCharCodes(pdf.bytes),
        matches(RegExp(r'/Subtype\s*/Image')),
      );
    });

    test('a broken logo fails with InvoiceImageException', () async {
      final invoice = sampleInvoice().copyWith(
        seller: Business(
          name: 'ABC',
          logo: InvoiceLogo.memory(Uint8List.fromList([1, 2, 3, 4])),
        ),
      );
      await expectLater(
        InvoiceGenerator.generate(invoice),
        throwsA(isA<InvoiceImageException>()),
      );
    });
  });
}
