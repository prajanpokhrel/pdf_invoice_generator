import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceItem', () {
    test('supports decimal quantities', () {
      for (final q in [1, 2, 2.5, 0.75]) {
        final item = InvoiceItem(name: 'x', quantity: q, unitPrice: 10);
        expect(item.quantity, q);
      }
    });

    test('optional fields', () {
      final item = InvoiceItem(
        name: 'Consulting',
        description: 'Architecture review',
        quantity: 3,
        unitPrice: 80,
        sku: 'CONS-01',
        unit: 'hrs',
        discount: const Discount.percentage(5),
      );
      expect(item.sku, 'CONS-01');
      expect(item.unit, 'hrs');
      expect(item.discount, const Discount.percentage(5));
    });

    group('taxes', () {
      test('null by default: inherit the invoice taxes', () {
        final item = InvoiceItem(name: 'x', quantity: 1, unitPrice: 1);
        expect(item.taxes, isNull);
      });

      test('tax shortcut becomes a one-element list', () {
        final item = InvoiceItem(
          name: 'x',
          quantity: 1,
          unitPrice: 1,
          tax: const Tax(name: 'GST', percentage: 5),
        );
        expect(item.taxes, [const Tax(name: 'GST', percentage: 5)]);
      });

      test('empty list means tax-exempt', () {
        final item = InvoiceItem(
          name: 'x',
          quantity: 1,
          unitPrice: 1,
          taxes: const [],
        );
        expect(item.taxes, isEmpty);
      });

      test('passing both tax and taxes throws', () {
        expect(
          () => InvoiceItem(
            name: 'x',
            quantity: 1,
            unitPrice: 1,
            tax: const Tax(name: 'A', percentage: 1),
            taxes: const [Tax(name: 'B', percentage: 2)],
          ),
          throwsArgumentError,
        );
      });

      test('list is copied and read-only', () {
        final source = [const Tax(name: 'A', percentage: 1)];
        final item = InvoiceItem(
          name: 'x',
          quantity: 1,
          unitPrice: 1,
          taxes: source,
        );
        source.add(const Tax(name: 'B', percentage: 2));
        expect(item.taxes, hasLength(1));
        expect(
          () => item.taxes!.add(const Tax(name: 'C', percentage: 3)),
          throwsUnsupportedError,
        );
      });
    });

    test('equality by value, including taxes', () {
      InvoiceItem make() => InvoiceItem(
            name: 'x',
            quantity: 2.5,
            unitPrice: 10,
            tax: const Tax(name: 'VAT', percentage: 13),
          );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
      expect(make(), isNot(make().copyWith(quantity: 3)));
    });
  });
}
