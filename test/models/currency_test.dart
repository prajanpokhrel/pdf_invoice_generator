import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    test('built-in list contains the 8 required currencies', () {
      expect(
        Currency.values.map((c) => c.code),
        ['USD', 'EUR', 'GBP', 'INR', 'NPR', 'AUD', 'CAD', 'JPY'],
      );
    });

    test('codes are unique', () {
      final codes = Currency.values.map((c) => c.code).toSet();
      expect(codes.length, Currency.values.length);
    });

    test('JPY has no decimal digits, others have 2', () {
      expect(Currency.jpy.decimalDigits, 0);
      for (final c in Currency.values.where((c) => c != Currency.jpy)) {
        expect(c.decimalDigits, 2, reason: c.code);
      }
    });

    test('custom currency from the requirements', () {
      const npr = Currency(code: 'NPR', symbol: 'Rs.', decimalDigits: 2);
      expect(npr.code, 'NPR');
      expect(npr.symbol, 'Rs.');
      expect(npr.symbolBeforeAmount, isTrue);
    });

    test('equality is by value', () {
      const a = Currency(code: 'XYZ', symbol: 'x');
      const b = Currency(code: 'XYZ', symbol: 'x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.copyWith(decimalDigits: 3)));
    });

    test('copyWith replaces only given fields', () {
      final c = Currency.eur.copyWith(symbolBeforeAmount: false);
      expect(c.code, 'EUR');
      expect(c.symbol, '€');
      expect(c.symbolBeforeAmount, isFalse);
    });

    test('rejects out-of-range decimal digits in debug mode', () {
      expect(
        () => Currency(code: 'BAD', symbol: 'b', decimalDigits: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
