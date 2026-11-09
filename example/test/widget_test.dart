import 'package:flutter/material.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_invoice_generator_example/main.dart';
import 'package:flutter_invoice_generator_example/src/invoice_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceDraft', () {
    test('the sample draft is a valid invoice', () {
      final invoice = InvoiceDraft().toInvoice();
      expect(InvoiceValidator.validate(invoice), isEmpty);
      // 500 + 200 + 200 = 900, -10% = 810, +13% VAT = 915.30
      expect(InvoiceCalculator.calculate(invoice).total, 915.3);
    });

    test('discount modes and zero tax map to the package models', () {
      final draft = InvoiceDraft()
        ..discountMode = DiscountMode.fixed
        ..discountValue = 50
        ..taxPercentage = 0;
      final invoice = draft.toInvoice();
      expect(invoice.discount, const Discount.fixed(50));
      expect(invoice.taxes, isEmpty);

      draft.discountMode = DiscountMode.none;
      expect(draft.toInvoice().discount, isNull);
    });

    test('blank optional fields become null', () {
      final draft = InvoiceDraft()..customerEmail = '  ';
      expect(draft.toInvoice().customer.email, isNull);
    });

    test('add and remove items', () {
      final draft = InvoiceDraft();
      var notified = 0;
      draft.addListener(() => notified++);
      draft.addItem();
      expect(draft.items, hasLength(4));
      draft.removeItem(draft.items.first);
      expect(draft.items, hasLength(3));
      expect(notified, 2);
    });
  });

  testWidgets('wide layout shows the editor next to the preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const InvoiceStudioApp());
    expect(find.text('Invoice Studio'), findsOneWidget);
    expect(find.text('Template & style'), findsOneWidget);
    expect(find.byType(InvoicePreview), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Print'), findsOneWidget);
    expect(find.byTooltip('Save'), findsOneWidget);
  });

  testWidgets('phone layout uses Edit / Preview tabs', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const InvoiceStudioApp());
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('removing every item shows the validation banner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const InvoiceStudioApp());
    while (find.byTooltip('Remove item').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Remove item').first);
      await tester.pump();
    }
    expect(find.text('items: must contain at least one item'), findsOneWidget);
    expect(
      find.text('No items yet. An invoice needs at least one.'),
      findsOneWidget,
    );
    // Let the debounce timer fire so no timers are pending at the end.
    await tester.pump(const Duration(milliseconds: 400));
  });
}
