import 'dart:math';

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/sample_invoice.dart';

/// Builds an invoice with only the parts a calculation test cares about.
Invoice invoiceWith(
  List<InvoiceItem> items, {
  List<Tax>? taxes,
  Discount? discount,
  Currency currency = Currency.usd,
}) {
  return Invoice(
    invoiceNumber: 'T-1',
    issueDate: DateTime(2026, 11, 7),
    seller: const Business(name: 'Seller'),
    customer: const Customer(name: 'Customer'),
    items: items,
    taxes: taxes,
    discount: discount,
    currency: currency,
  );
}

InvoiceItem item(
  num quantity,
  num unitPrice, {
  Discount? discount,
  Tax? tax,
  List<Tax>? taxes,
}) =>
    InvoiceItem(
      name: 'Item',
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      tax: tax,
      taxes: taxes,
    );

const vat13 = Tax(name: 'VAT', percentage: 13);

void main() {
  group('basic arithmetic', () {
    test(r'1 x $100 = $100', () {
      final t = InvoiceCalculator.calculate(invoiceWith([item(1, 100)]));
      expect(t.subtotal, 100);
      expect(t.discountAmount, 0);
      expect(t.taxableAmount, 100);
      expect(t.taxAmount, 0);
      expect(t.total, 100);
    });

    test(r'2 x $100 = $200', () {
      final t = InvoiceCalculator.calculate(invoiceWith([item(2, 100)]));
      expect(t.lines.single.lineTotal, 200);
      expect(t.total, 200);
    });

    test('multiple items', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(3, 10), item(1.5, 20), item(0.25, 8)]),
      );
      expect(t.lines.map((l) => l.lineTotal), [30, 30, 2]);
      expect(t.subtotal, 62);
      expect(t.total, 62);
    });

    test('zero quantity contributes nothing', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(0, 500), item(1, 10)]),
      );
      expect(t.lines.first.lineTotal, 0);
      expect(t.total, 10);
    });
  });

  group('decimals', () {
    test('decimal quantity', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(2.5, 40), item(0.75, 9.99)]),
      );
      expect(t.lines[0].lineTotal, 100);
      expect(t.lines[1].lineTotal, 7.49); // 7.4925 rounds down
      expect(t.total, 107.49);
    });

    test('decimal price', () {
      final t = InvoiceCalculator.calculate(invoiceWith([item(3, 19.99)]));
      expect(t.total, 59.97);
    });

    test('no floating-point drift: 0.1 + 0.2 == 0.3', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(1, 0.1), item(1, 0.2)]),
      );
      expect(t.total, 0.3);
    });

    test('100 items of 0.01 add up to exactly 1.00', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(List.generate(100, (_) => item(1, 0.01))),
      );
      expect(t.total, 1.0);
      expect(t.totalInMinorUnits, 100);
    });
  });

  group('discounts', () {
    test('10% discount', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(2, 100)], discount: const Discount.percentage(10)),
      );
      expect(t.discountAmount, 20);
      expect(t.taxableAmount, 180);
      expect(t.total, 180);
    });

    test('fixed discount', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(2, 100)], discount: const Discount.fixed(50)),
      );
      expect(t.discountAmount, 50);
      expect(t.total, 150);
    });

    test('zero discount', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(1, 100)], discount: const Discount.percentage(0)),
      );
      expect(t.discountAmount, 0);
      expect(t.total, 100);
    });

    test('100% discount gives zero total', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [item(1, 100)],
          taxes: [vat13],
          discount: const Discount.percentage(100),
        ),
      );
      expect(t.total, 0);
    });

    test('item-level discounts are applied before the invoice discount', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [
            item(2, 100, discount: const Discount.percentage(10)), // 180
            item(1, 100, discount: const Discount.fixed(15)), // 85
          ],
          discount: const Discount.percentage(10),
        ),
      );
      expect(t.lines[0].grossAmount, 200);
      expect(t.lines[0].discountAmount, 20);
      expect(t.lines[0].lineTotal, 180);
      expect(t.lines[1].lineTotal, 85);
      expect(t.subtotal, 265);
      expect(t.discountAmount, 26.5);
      expect(t.total, 238.5);
    });

    test('invoice discount shares always add up to the discount', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [item(1, 1), item(1, 1), item(1, 1)],
          discount: const Discount.fixed(1),
        ),
      );
      expect(t.lines.map((l) => l.invoiceDiscountShare), [0.34, 0.33, 0.33]);
      expect(t.taxableAmount, 2);
    });
  });

  group('taxes', () {
    test('13% tax', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(1, 100)], taxes: [vat13]),
      );
      expect(t.taxLines.single.tax, vat13);
      expect(t.taxLines.single.taxableAmount, 100);
      expect(t.taxAmount, 13);
      expect(t.total, 113);
    });

    test('no tax: no tax lines', () {
      final t = InvoiceCalculator.calculate(invoiceWith([item(1, 100)]));
      expect(t.taxLines, isEmpty);
      expect(t.taxAmount, 0);
    });

    test('zero tax is still listed', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [item(1, 100)],
          taxes: const [Tax(name: 'VAT', percentage: 0)],
        ),
      );
      expect(t.taxLines, hasLength(1));
      expect(t.taxAmount, 0);
      expect(t.total, 100);
    });

    test('tax is applied after the discount', () {
      final t = InvoiceCalculator.calculate(sampleInvoice());
      // 500 + 2 x 100 = 700, -10% = 630, +13% = 81.90
      expect(t.subtotal, 700);
      expect(t.discountAmount, 70);
      expect(t.taxableAmount, 630);
      expect(t.taxAmount, 81.9);
      expect(t.total, 711.9);
      expect(t.totalInMinorUnits, 71190);
    });

    test('multiple taxes (CGST + SGST) are each applied to the base', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [item(1, 1000)],
          taxes: const [
            Tax(name: 'CGST', percentage: 9),
            Tax(name: 'SGST', percentage: 9),
          ],
        ),
      );
      expect(t.taxLines.map((l) => l.amount), [90, 90]);
      expect(t.total, 1180);
    });

    test('item taxes override, and an empty list makes an item exempt', () {
      const gst5 = Tax(name: 'GST', percentage: 5);
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [
            item(1, 100), // inherits VAT 13%
            item(1, 100, tax: gst5),
            item(1, 100, taxes: const []), // exempt
          ],
          taxes: [vat13],
          discount: const Discount.percentage(10),
        ),
      );
      // Each line: 100 - 10 (share of discount) = 90 taxable.
      expect(t.lines.map((l) => l.taxableAmount), [90, 90, 90]);
      expect(t.lines[2].taxes, isEmpty);
      expect(t.taxLines.map((l) => l.tax), [vat13, gst5]);
      expect(t.taxLines.map((l) => l.amount), [11.7, 4.5]);
      expect(t.total, 286.2);
    });

    test('tax is rounded once per rate, not once per line', () {
      // 3 lines of 0.10 at 5%: per line 0.005 -> 0.01 each = 0.03,
      // but on the sum 0.30 x 5% = 0.015 -> 0.02.
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [item(1, 0.1), item(1, 0.1), item(1, 0.1)],
          taxes: const [Tax(name: 'T', percentage: 5)],
        ),
      );
      expect(t.taxAmount, 0.02);
    });
  });

  group('rounding (half away from zero)', () {
    test('1.005 rounds up to 1.01', () {
      final t = InvoiceCalculator.calculate(invoiceWith([item(1, 1.005)]));
      expect(t.total, 1.01);
    });

    test('0.125 rounds to 0.13 and 0.124 to 0.12', () {
      expect(
        InvoiceCalculator.calculate(invoiceWith([item(1, 0.125)])).total,
        0.13,
      );
      expect(
        InvoiceCalculator.calculate(invoiceWith([item(1, 0.124)])).total,
        0.12,
      );
    });

    test('tax half-cent rounds up: 13% of 0.50 = 0.065 -> 0.07', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(1, 0.5)], taxes: [vat13]),
      );
      expect(t.taxAmount, 0.07);
    });

    test('JPY rounds to whole yen', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith(
          [item(3, 333.5)], // 1000.5 -> 1001
          taxes: const [Tax(name: 'Consumption tax', percentage: 10)],
          currency: Currency.jpy,
        ),
      );
      expect(t.subtotal, 1001);
      expect(t.taxAmount, 100); // 100.1 -> 100
      expect(t.total, 1101);
      expect(t.totalInMinorUnits, 1101);
    });

    test('three-decimal currency', () {
      const kwd = Currency(code: 'KWD', symbol: 'KD', decimalDigits: 3);
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(1, 1.2345)], currency: kwd),
      );
      expect(t.total, 1.235);
      expect(t.totalInMinorUnits, 1235);
    });
  });

  group('large values', () {
    test('millions of units at a high price stay exact', () {
      final t = InvoiceCalculator.calculate(
        invoiceWith([item(1000000, 999999.99)], taxes: [vat13]),
      );
      expect(t.subtotal, 999999990000);
      expect(t.taxAmount, 129999998700);
      expect(t.total, 1129999988700);
      expect(t.totalInMinorUnits, 112999998870000);
    });
  });

  group('invariants', () {
    test('totals always add up exactly, for 300 random invoices', () {
      final random = Random(42);
      num money() => (random.nextInt(100000) / 100); // 0.00 - 999.99
      num qty() => [0, 1, 2, 0.5, 0.75, 1.25, 3, 10][random.nextInt(8)];

      for (var n = 0; n < 300; n++) {
        final t = InvoiceCalculator.calculate(
          invoiceWith(
            List.generate(1 + random.nextInt(8), (_) => item(qty(), money())),
            taxes: [
              Tax(name: 'A', percentage: random.nextInt(2000) / 100),
              if (random.nextBool()) const Tax(name: 'B', percentage: 2.5),
            ],
            discount: random.nextBool()
                ? Discount.percentage(random.nextInt(100))
                : null,
          ),
        );
        int cents(double v) => (v * 100).round();
        final lineSum = t.lines.fold(0, (a, l) => a + cents(l.lineTotal));
        final taxSum = t.taxLines.fold(0, (a, l) => a + cents(l.amount));
        final shareSum =
            t.lines.fold(0, (a, l) => a + cents(l.invoiceDiscountShare));

        expect(cents(t.subtotal), lineSum, reason: 'invoice $n subtotal');
        expect(shareSum, cents(t.discountAmount), reason: 'invoice $n shares');
        expect(
          cents(t.taxableAmount),
          cents(t.subtotal) - cents(t.discountAmount),
          reason: 'invoice $n taxable',
        );
        expect(cents(t.taxAmount), taxSum, reason: 'invoice $n tax');
        expect(
          cents(t.total),
          cents(t.taxableAmount) + cents(t.taxAmount),
          reason: 'invoice $n total',
        );
        expect(t.totalInMinorUnits, cents(t.total));
      }
    });
  });

  group('validation', () {
    test('invalid invoices throw InvoiceValidationException', () {
      expect(
        () => InvoiceCalculator.calculate(invoiceWith([item(1, -5)])),
        throwsA(isA<InvoiceValidationException>()),
      );
    });

    test('result lists are read-only', () {
      final t = InvoiceCalculator.calculate(sampleInvoice());
      expect(() => t.lines.clear(), throwsUnsupportedError);
      expect(() => t.taxLines.clear(), throwsUnsupportedError);
    });
  });
}
