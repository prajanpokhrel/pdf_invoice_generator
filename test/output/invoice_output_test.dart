import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_platforms.dart';
import '../helpers/sample_invoice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePrinting printing;
  late Directory temp;

  setUp(() {
    printing = FakePrinting.install();
    temp = Directory.systemTemp.createTempSync('invoice_output_test');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  group('print', () {
    test('opens the print dialog with the generated PDF', () async {
      final ok = await InvoiceGenerator.print(
        sampleInvoice(),
        theme: const InvoiceTheme(pageFormat: PdfPageFormat.letter),
      );
      expect(ok, isTrue);
      final call = printing.callsTo(#layoutPdf).single;
      expect(call.positionalArguments[2], 'INV-1001.pdf'); // job name
      expect(call.positionalArguments[3], PdfPageFormat.letter);
      expect(call.positionalArguments[4], isFalse); // no re-layout
      expect(String.fromCharCodes(printing.printedBytes!.take(5)), '%PDF-');
    });

    test('reports a cancelled dialog as false', () async {
      printing.result = false;
      expect(await InvoiceGenerator.print(sampleInvoice()), isFalse);
    });

    test('custom job name', () async {
      await InvoiceGenerator.print(sampleInvoice(), jobName: 'Invoice 1001');
      expect(
        printing.callsTo(#layoutPdf).single.positionalArguments[2],
        'Invoice 1001',
      );
    });
  });

  group('share', () {
    test('passes the PDF and the optional email fields', () async {
      final ok = await InvoiceGenerator.share(
        sampleInvoice(),
        subject: 'Invoice INV-1001',
        text: 'Please find attached.',
        emails: const ['john@example.com'],
      );
      expect(ok, isTrue);
      final args = printing.callsTo(#sharePdf).single.positionalArguments;
      expect(String.fromCharCodes((args[0] as Uint8List).take(5)), '%PDF-');
      expect(args[1], 'INV-1001.pdf');
      expect(args[3], 'Invoice INV-1001');
      expect(args[4], 'Please find attached.');
      expect(args[5], ['john@example.com']);
    });

    test('an existing PDF can be shared without generating it again', () async {
      final pdf = await InvoiceGenerator.generate(sampleInvoice());
      await pdf.share();
      await pdf.share();
      final shared = printing.callsTo(#sharePdf);
      expect(shared, hasLength(2));
      expect(identical(shared[0].positionalArguments[0], pdf.bytes), isTrue);
    });
  });

  group('save', () {
    test('writes the PDF to the given directory', () async {
      final result = await InvoiceGenerator.save(
        sampleInvoice(),
        directory: temp.path,
      );
      expect(result.isDownload, isFalse);
      expect(result.fileName, 'INV-1001.pdf');
      final file = File(result.path!);
      expect(file.existsSync(), isTrue);
      expect(file.path, startsWith(temp.path));
      expect(String.fromCharCodes(file.readAsBytesSync().take(5)), '%PDF-');
    });

    test('saved file is exactly the generated PDF', () async {
      final pdf = await InvoiceGenerator.generate(sampleInvoice());
      final result = await pdf.save(directory: temp.path);
      expect(File(result.path!).readAsBytesSync(), pdf.bytes);
    });

    test('custom file name, nested folder, replaces an existing file',
        () async {
      final dir = '${temp.path}/invoices/2026';
      final first = await InvoiceGenerator.save(
        sampleInvoice(),
        directory: dir,
        fileName: 'latest.pdf',
      );
      final second = await InvoiceGenerator.save(
        sampleInvoice().copyWith(invoiceNumber: 'INV-2'),
        directory: dir,
        fileName: 'latest.pdf',
      );
      expect(first.path, second.path);
      expect(Directory(dir).listSync(), hasLength(1));
    });

    test('defaults to the app documents directory', () async {
      FakePathProvider.install(temp.path);
      final result = await InvoiceGenerator.save(sampleInvoice());
      expect(result.path, '${temp.path}${Platform.pathSeparator}INV-1001.pdf');
      expect(File(result.path!).existsSync(), isTrue);
    });

    test('an unwritable location fails with InvoiceOutputException', () async {
      final notADirectory = File('${temp.path}/file.txt')
        ..writeAsStringSync('x');
      await expectLater(
        InvoiceGenerator.save(sampleInvoice(), directory: notADirectory.path),
        throwsA(isA<InvoiceOutputException>()),
      );
    });
  });

  group('errors', () {
    test('a missing plugin gives a helpful message', () async {
      printing.error = MissingPluginException('No implementation found');
      await expectLater(
        InvoiceGenerator.share(sampleInvoice()),
        throwsA(
          isA<InvoiceOutputException>()
              .having((e) => e.message, 'message', contains('hot restart'))
              .having((e) => e.cause, 'cause', isA<MissingPluginException>()),
        ),
      );
    });

    test('any other platform error becomes InvoiceOutputException', () async {
      printing.error = PlatformException(code: 'boom');
      await expectLater(
        InvoiceGenerator.print(sampleInvoice()),
        throwsA(isA<InvoiceOutputException>()),
      );
    });

    test('invalid data fails before any dialog opens', () async {
      for (final action in [
        () => InvoiceGenerator.print(sampleInvoice(items: const [])),
        () => InvoiceGenerator.share(sampleInvoice(items: const [])),
        () => InvoiceGenerator.save(
              sampleInvoice(items: const []),
              directory: temp.path,
            ),
      ]) {
        await expectLater(
          action(),
          throwsA(isA<InvoiceValidationException>()),
        );
      }
      expect(printing.calls, isEmpty);
      expect(temp.listSync(), isEmpty);
    });

    test('all output errors can be caught as InvoiceException', () {
      expect(
        const InvoiceOutputException('x'),
        isA<InvoiceException>(),
      );
    });
  });
}
