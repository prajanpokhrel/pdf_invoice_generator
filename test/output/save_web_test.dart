// Run with: flutter test --platform chrome test/output/save_web_test.dart
@TestOn('browser')
library;

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_platforms.dart';
import '../helpers/sample_invoice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('on the web, save() downloads the file instead of writing it', () async {
    final printing = FakePrinting.install();
    final result = await InvoiceGenerator.save(
      sampleInvoice(),
      // Built-in font: keeps this test independent of asset loading.
      theme: InvoiceTheme(
        font: Font.helvetica(),
        boldFont: Font.helveticaBold(),
      ),
    );
    expect(result.isDownload, isTrue);
    expect(result.path, isNull);
    expect(result.fileName, 'INV-1001.pdf');
    final download = printing.callsTo(#sharePdf).single;
    expect(download.positionalArguments[1], 'INV-1001.pdf');
  });
}
