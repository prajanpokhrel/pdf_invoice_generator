// Runs inside the real app, with the real native plugins.
//
//   flutter test integration_test -d macos
//
// It checks that the printing plugin really renders the invoice pages and
// saves a picture of the window, plus the generated PDF, to the temp folder.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_invoice_generator_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      int count(Type t) => find.byType(t).evaluate().length;
      fail(
        'Timed out. spinners=${count(CircularProgressIndicator)} '
        'errorText=${find.textContaining('could not').evaluate().length} '
        'texts=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).where((t) => t != null).take(40).toList()}',
      );
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
}

Future<String> capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late String path;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    path = '${Directory.systemTemp.path}/$name.png';
    await File(path).writeAsBytes(png!.buffer.asUint8List());
  });
  return path;
}

/// Page images drawn by the native plugin inside the preview.
Finder renderedPages() => find.descendant(
      of: find.byType(InvoicePreview),
      matching: find.byType(Image),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real plugin renders the preview; templates switch',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const InvoiceStudioApp()),
    );

    // The test window is narrower than 960 px, so the app uses the phone
    // layout with Edit / Preview tabs.
    final tabs = find.byType(TabBar).evaluate().isNotEmpty;

    Future<void> showPreview(String name) async {
      if (tabs) {
        await tester.tap(find.text('Preview'));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await pumpUntil(tester, () => renderedPages().evaluate().isNotEmpty);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
      // ignore: avoid_print
      print('SCREENSHOT ${await capture(tester, key, name)}');
    }

    await showPreview('studio_modern');
    expect(renderedPages(), findsWidgets);

    if (tabs) {
      await tester.tap(find.text('Edit'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.text('Minimal'));
    // Wait for the editor debounce (350 ms) so the new template is applied.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump();
    await showPreview('studio_minimal');
  });

  testWidgets('save() writes a real file in the sandbox', (tester) async {
    late InvoiceSaveResult result;
    await tester.runAsync(() async {
      final pdf = await InvoiceGenerator.generate(
        Invoice(
          invoiceNumber: 'INT-TEST-1',
          issueDate: DateTime(2026, 11, 7),
          seller: const Business(name: 'ABC Technologies'),
          customer: const Customer(name: 'John Doe'),
          items: [InvoiceItem(name: 'Check', quantity: 1, unitPrice: 1)],
        ),
      );
      result = await pdf.save();
    });
    // ignore: avoid_print
    print('SAVED ${result.path}');
    expect(File(result.path!).existsSync(), isTrue);
    expect(result.path, contains('Documents'));
  });
}
