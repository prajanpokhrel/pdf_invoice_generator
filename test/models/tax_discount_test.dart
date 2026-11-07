import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tax', () {
    test('stores name and percentage', () {
      const vat = Tax(name: 'VAT', percentage: 13);
      expect(vat.name, 'VAT');
      expect(vat.percentage, 13);
    });

    test('accepts decimal percentages', () {
      const gst = Tax(name: 'GST', percentage: 2.5);
      expect(gst.percentage, 2.5);
    });

    test('int and double percentages with the same value are equal', () {
      expect(
        const Tax(name: 'VAT', percentage: 13),
        const Tax(name: 'VAT', percentage: 13.0),
      );
    });

    test('copyWith', () {
      const vat = Tax(name: 'VAT', percentage: 13);
      expect(
        vat.copyWith(percentage: 15),
        const Tax(name: 'VAT', percentage: 15),
      );
    });
  });

  group('Discount', () {
    test('named constructors set the type', () {
      expect(const Discount.percentage(10).type, DiscountType.percentage);
      expect(const Discount.fixed(50).type, DiscountType.fixed);
    });

    test('short and long forms are equal', () {
      expect(
        const Discount.percentage(10),
        const Discount(type: DiscountType.percentage, value: 10),
      );
    });

    test('percentage and fixed with same value are different', () {
      expect(
        const Discount.percentage(10),
        isNot(const Discount.fixed(10)),
      );
    });

    test('optional label', () {
      const d = Discount.fixed(5, label: 'Loyalty');
      expect(d.label, 'Loyalty');
    });
  });
}
