import 'package:flutter/material.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import '../helpers/sample_invoice.dart';

/// Records what the preview reports.
final class Recorder {
  final generated = <InvoicePdf>[];
  final errors = <InvoiceException>[];
  int get events => generated.length + errors.length;
}

/// Pumps until [recorder] has seen [events] events.
///
/// PDF generation does real asynchronous work (loading fonts, encoding), so
/// it must run inside `runAsync`; widget tests otherwise use fake time.
Future<void> waitForEvents(
  WidgetTester tester,
  Recorder recorder,
  int events,
) async {
  for (var i = 0; i < 100 && recorder.events < events; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(recorder.events, events, reason: 'timed out waiting for the PDF');
  // The generation future was started inside the test's fake-async zone, so
  // its final steps (setState) run as microtasks *during* the last pump,
  // after that frame was built. One more pump draws the new state.
  await tester.pump();
}

Widget app(
  Invoice invoice,
  Recorder recorder, {
  InvoiceTemplate template = InvoiceTemplate.classic,
  InvoiceTheme theme = const InvoiceTheme(),
  bool allowPrinting = false,
  WidgetBuilder? loadingBuilder,
  Widget Function(BuildContext, InvoiceException)? errorBuilder,
}) {
  return MaterialApp(
    home: Scaffold(
      body: InvoicePreview(
        invoice: invoice,
        template: template,
        theme: theme,
        allowPrinting: allowPrinting,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        onGenerated: recorder.generated.add,
        onError: recorder.errors.add,
      ),
    ),
  );
}

PdfPreview pdfPreview(WidgetTester tester) =>
    tester.widget<PdfPreview>(find.byType(PdfPreview));

void main() {
  testWidgets('shows a loader, then the real PDF', (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(app(sampleInvoice(), recorder));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PdfPreview), findsNothing);

    await waitForEvents(tester, recorder, 1);
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(recorder.generated.single.totals.total, 711.9);
    expect(recorder.generated.single.pageCount, 1);

    // The bytes shown are exactly the generated PDF.
    final shown = await pdfPreview(tester).build(PdfPageFormat.a4);
    expect(shown, recorder.generated.single.bytes);
  });

  testWidgets('toolbar is hidden unless printing or sharing is allowed',
      (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(app(sampleInvoice(), recorder));
    await waitForEvents(tester, recorder, 1);
    expect(pdfPreview(tester).useActions, isFalse);
    expect(pdfPreview(tester).canChangePageFormat, isFalse);

    // Showing the toolbar is presentation only: no new PDF is generated.
    await tester.pumpWidget(
      app(sampleInvoice(), recorder, allowPrinting: true),
    );
    expect(recorder.generated, hasLength(1));
    expect(pdfPreview(tester).useActions, isTrue);
    expect(pdfPreview(tester).allowPrinting, isTrue);
    expect(pdfPreview(tester).allowSharing, isFalse);
  });

  testWidgets('invalid data shows the problems instead of crashing',
      (tester) async {
    final recorder = Recorder();
    final invalid = sampleInvoice(
      items: [InvoiceItem(name: 'Broken', quantity: -1, unitPrice: 10)],
    );
    await tester.pumpWidget(app(invalid, recorder));
    await waitForEvents(tester, recorder, 1);

    expect(recorder.errors.single, isA<InvoiceValidationException>());
    expect(find.text('The invoice could not be generated'), findsOneWidget);
    expect(
      find.text('items[0].quantity: must not be negative (got -1)'),
      findsOneWidget,
    );
    expect(find.byType(PdfPreview), findsNothing);
  });

  testWidgets('custom loading and error builders', (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(
      app(
        sampleInvoice(items: const []),
        recorder,
        loadingBuilder: (_) => const Text('Preparing…'),
        errorBuilder: (_, e) => Text('Oops: ${e.runtimeType}'),
      ),
    );
    expect(find.text('Preparing…'), findsOneWidget);
    await waitForEvents(tester, recorder, 1);
    expect(find.text('Oops: InvoiceValidationException'), findsOneWidget);
  });

  testWidgets('does not regenerate when inputs are equal', (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(app(sampleInvoice(), recorder));
    await waitForEvents(tester, recorder, 1);
    final firstBuild = pdfPreview(tester).build;

    // New objects with the same values: a typical parent rebuild.
    await tester.pumpWidget(
      app(
        sampleInvoice(),
        recorder,
        theme: const InvoiceTheme().copyWith(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(recorder.generated, hasLength(1));
    // Same function object, so PdfPreview does not re-render (no flicker).
    expect(identical(pdfPreview(tester).build, firstBuild), isTrue);
  });

  testWidgets('regenerates when the invoice, template or theme changes',
      (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(app(sampleInvoice(), recorder));
    await waitForEvents(tester, recorder, 1);
    final firstBuild = pdfPreview(tester).build;

    await tester.pumpWidget(
      app(sampleInvoice().copyWith(invoiceNumber: 'INV-2'), recorder),
    );
    // The previous PDF stays visible while the new one is generated.
    expect(find.byType(PdfPreview), findsOneWidget);
    await waitForEvents(tester, recorder, 2);
    expect(recorder.generated.last.fileName, 'INV-2.pdf');
    expect(identical(pdfPreview(tester).build, firstBuild), isFalse);

    await tester.pumpWidget(
      app(
        sampleInvoice().copyWith(invoiceNumber: 'INV-2'),
        recorder,
        template: InvoiceTemplate.modern,
      ),
    );
    await waitForEvents(tester, recorder, 3);

    await tester.pumpWidget(
      app(
        sampleInvoice().copyWith(invoiceNumber: 'INV-2'),
        recorder,
        template: InvoiceTemplate.modern,
        theme: const InvoiceTheme(pageFormat: PdfPageFormat.letter),
      ),
    );
    await waitForEvents(tester, recorder, 4);
  });

  testWidgets('several quick edits: the latest one is shown', (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(app(sampleInvoice(), recorder));
    await waitForEvents(tester, recorder, 1);

    for (final n in ['A', 'B', 'C']) {
      await tester.pumpWidget(
        app(sampleInvoice().copyWith(invoiceNumber: 'INV-$n'), recorder),
      );
    }
    // Let every pending generation finish. Results of generations that were
    // superseded before finishing are dropped, so the screen can never jump
    // back to an older version.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump();

    expect(recorder.generated.last.fileName, 'INV-C.pdf');
    final shown = await pdfPreview(tester).build(PdfPageFormat.a4);
    expect(shown, recorder.generated.last.bytes);
  });

  testWidgets('recovers after an error is fixed', (tester) async {
    final recorder = Recorder();
    await tester.pumpWidget(app(sampleInvoice(items: const []), recorder));
    await waitForEvents(tester, recorder, 1);
    expect(find.byType(PdfPreview), findsNothing);

    await tester.pumpWidget(app(sampleInvoice(), recorder));
    await waitForEvents(tester, recorder, 2);
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(find.text('The invoice could not be generated'), findsNothing);
  });
}
