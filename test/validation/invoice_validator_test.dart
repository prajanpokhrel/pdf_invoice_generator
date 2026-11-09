import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/sample_invoice.dart';

List<String> fields(Invoice invoice) =>
    InvoiceValidator.validate(invoice).map((i) => i.field).toList();

Invoice withItems(List<InvoiceItem> items) =>
    sampleInvoice().copyWith(items: items);

InvoiceItem item({
  String name = 'x',
  num quantity = 1,
  num unitPrice = 10,
  Discount? discount,
  List<Tax>? taxes,
}) =>
    InvoiceItem(
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      taxes: taxes,
    );

void main() {
  test('the sample invoice is valid', () {
    expect(InvoiceValidator.validate(sampleInvoice()), isEmpty);
    expect(
      () => InvoiceValidator.ensureValid(sampleInvoice()),
      returnsNormally,
    );
  });

  group('required data', () {
    test('blank invoice number', () {
      expect(
        fields(sampleInvoice().copyWith(invoiceNumber: '   ')),
        ['invoiceNumber'],
      );
    });

    test('blank seller and customer names', () {
      final invoice = sampleInvoice().copyWith(
        seller: const Business(name: ''),
        customer: const Customer(name: ' '),
      );
      expect(fields(invoice), ['seller.name', 'customer.name']);
    });

    test('empty invoice (no items)', () {
      expect(fields(withItems(const [])), ['items']);
    });

    test('blank item name', () {
      expect(fields(withItems([item(name: '')])), ['items[0].name']);
    });

    test('due the same day is valid, even with an earlier time', () {
      final invoice = sampleInvoice().copyWith(
        issueDate: DateTime(2026, 11, 7, 15, 30), // like DateTime.now()
        dueDate: DateTime(2026, 11, 7), // midnight, same day
      );
      expect(fields(invoice), isEmpty);
    });

    test('due date before issue date', () {
      final invoice = sampleInvoice().copyWith(dueDate: DateTime(2020));
      expect(fields(invoice), ['dueDate']);
    });
  });

  group('quantities and prices', () {
    test('zero quantity and zero price are allowed', () {
      expect(fields(withItems([item(quantity: 0, unitPrice: 0)])), isEmpty);
    });

    test('negative values', () {
      expect(
        fields(withItems([item(quantity: -1), item(unitPrice: -0.01)])),
        ['items[0].quantity', 'items[1].unitPrice'],
      );
    });

    test('NaN and infinity', () {
      final issues = InvoiceValidator.validate(
        withItems([
          item(quantity: double.nan),
          item(unitPrice: double.infinity),
        ]),
      );
      expect(issues.map((i) => i.field), [
        'items[0].quantity',
        'items[1].unitPrice',
      ]);
      expect(issues.first.message, contains('finite'));
    });

    test('amounts too large to represent exactly', () {
      expect(
        fields(withItems([item(quantity: 1e9, unitPrice: 1e9)])),
        ['total'],
      );
    });
  });

  test('currency needs a code', () {
    final invoice = sampleInvoice(
      currency: const Currency(code: ' ', symbol: '?'),
    );
    expect(fields(invoice), ['currency.code']);
  });

  group('length limits (each item row must fit on one page)', () {
    test('item name, unit and sku', () {
      final issues = InvoiceValidator.validate(
        withItems([
          InvoiceItem(
            name: 'n' * 301,
            unit: 'u' * 31,
            sku: 's' * 101,
            quantity: 1,
            unitPrice: 1,
          ),
        ]),
      );
      expect(issues.map((i) => i.field), [
        'items[0].name',
        'items[0].unit',
        'items[0].sku',
      ]);
      expect(issues.first.message, contains('put long text in description'));
    });

    test('limits are inclusive', () {
      expect(
        fields(
          withItems([
            InvoiceItem(
              name: 'n' * 300,
              unit: 'u' * 30,
              sku: 's' * 100,
              quantity: 1,
              unitPrice: 1,
            ),
          ]),
        ),
        isEmpty,
      );
    });

    test('long descriptions are allowed', () {
      final invoice = withItems([
        InvoiceItem(
          name: 'x',
          description: 'd' * 20000,
          quantity: 1,
          unitPrice: 1,
        ),
      ]);
      expect(fields(invoice), isEmpty);
    });

    test('at most 10 taxes per item', () {
      final invoice = withItems([
        item(
          taxes: [for (var i = 0; i < 11; i++) Tax(name: 'T$i', percentage: 1)],
        ),
      ]);
      expect(fields(invoice), ['items[0].taxes']);
    });
  });

  group('taxes', () {
    test('percentage must be between 0 and 100', () {
      final invoice = sampleInvoice().copyWith(
        taxes: const [
          Tax(name: 'A', percentage: 101),
          Tax(name: 'B', percentage: -1),
          Tax(name: 'C', percentage: 0),
          Tax(name: 'D', percentage: 100),
        ],
      );
      expect(fields(invoice), ['taxes[0].percentage', 'taxes[1].percentage']);
    });

    test('blank tax name', () {
      final invoice = sampleInvoice().copyWith(
        taxes: const [Tax(name: '', percentage: 5)],
      );
      expect(fields(invoice), ['taxes[0].name']);
    });

    test('same tax listed twice', () {
      final invoice = sampleInvoice().copyWith(
        taxes: const [
          Tax(name: 'VAT', percentage: 13),
          Tax(name: 'VAT', percentage: 13),
        ],
      );
      expect(fields(invoice), ['taxes[1]']);
    });

    test('same name with different rates is allowed', () {
      final invoice = sampleInvoice().copyWith(
        taxes: const [
          Tax(name: 'VAT', percentage: 13),
          Tax(name: 'VAT', percentage: 5),
        ],
      );
      expect(fields(invoice), isEmpty);
    });

    test('item taxes are validated too', () {
      final invoice = withItems([
        item(taxes: const [Tax(name: 'GST', percentage: 200)]),
      ]);
      expect(fields(invoice), ['items[0].taxes[0].percentage']);
    });
  });

  group('discounts', () {
    test('percentage above 100', () {
      final invoice =
          sampleInvoice().copyWith(discount: const Discount.percentage(150));
      expect(fields(invoice), ['discount.value']);
    });

    test('negative fixed discount', () {
      final invoice =
          sampleInvoice().copyWith(discount: const Discount.fixed(-5));
      expect(fields(invoice), ['discount.value']);
    });

    test('fixed discount larger than the subtotal', () {
      // Subtotal of the sample invoice is 700.
      final issues = InvoiceValidator.validate(
        sampleInvoice().copyWith(discount: const Discount.fixed(700.01)),
      );
      expect(issues.single.field, 'discount.value');
      expect(issues.single.message, contains('700.00'));
    });

    test('fixed discount equal to the subtotal is allowed', () {
      final invoice =
          sampleInvoice().copyWith(discount: const Discount.fixed(700));
      expect(fields(invoice), isEmpty);
    });

    test('item fixed discount larger than the line', () {
      final invoice = withItems([
        item(quantity: 2, unitPrice: 10, discount: const Discount.fixed(25)),
      ]);
      expect(fields(invoice), ['items[0].discount.value']);
    });
  });

  test('reports every problem at once', () {
    final invoice = Invoice(
      invoiceNumber: '',
      issueDate: DateTime(2026),
      seller: const Business(name: 'S'),
      customer: const Customer(name: 'C'),
      items: [item(quantity: -1, unitPrice: -1)],
      tax: const Tax(name: 'VAT', percentage: 130),
    );
    expect(
      () => InvoiceValidator.ensureValid(invoice),
      throwsA(
        isA<InvoiceValidationException>().having(
          (e) => e.issues.map((i) => i.field),
          'fields',
          [
            'invoiceNumber',
            'items[0].quantity',
            'items[0].unitPrice',
            'taxes[0].percentage',
          ],
        ),
      ),
    );
  });
}
