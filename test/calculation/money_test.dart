// Tests for the internal exact-decimal helpers.
import 'package:flutter_invoice_generator/src/calculation/money.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt b(int v) => BigInt.from(v);

void main() {
  group('ExactDecimal.fromNum', () {
    void expectDecimal(num value, int mantissa, int scale) {
      final d = ExactDecimal.fromNum(value);
      expect(d.mantissa, b(mantissa), reason: '$value mantissa');
      expect(d.scale, scale, reason: '$value scale');
    }

    test('ints and simple decimals', () {
      expectDecimal(42, 42, 0);
      expectDecimal(2.5, 25, 1);
      expectDecimal(-0.75, -75, 2);
    });

    test('1.005 is read exactly, not as 1.00499999...', () {
      expectDecimal(1.005, 1005, 3);
    });

    test('exponent notation', () {
      expectDecimal(1e-7, 1, 7);
      expectDecimal(2.5e-7, 25, 8);
      final big = ExactDecimal.fromNum(1e21);
      expect(big.mantissa, BigInt.parse('1000000000000000000000'));
      expect(big.scale, 0);
    });

    test('rejects NaN and infinity', () {
      expect(() => ExactDecimal.fromNum(double.nan), throwsArgumentError);
      expect(() => ExactDecimal.fromNum(double.infinity), throwsArgumentError);
    });
  });

  group('roundDiv (half away from zero)', () {
    test('rounds halves away from zero', () {
      expect(roundDiv(b(5), b(10)), b(1)); // 0.5 -> 1
      expect(roundDiv(b(15), b(10)), b(2)); // 1.5 -> 2
      expect(roundDiv(b(25), b(10)), b(3)); // 2.5 -> 3 (not banker's 2)
      expect(roundDiv(b(-5), b(10)), b(-1)); // -0.5 -> -1
    });

    test('rounds non-halves to nearest', () {
      expect(roundDiv(b(49), b(100)), b(0));
      expect(roundDiv(b(51), b(100)), b(1));
      expect(roundDiv(b(-49), b(100)), b(0));
    });
  });

  group('conversions', () {
    test('toMinorUnits', () {
      expect(toMinorUnits(12.345, 2), b(1235));
      expect(toMinorUnits(12.344, 2), b(1234));
      expect(toMinorUnits(1.005, 2), b(101));
      expect(toMinorUnits(999.5, 0), b(1000));
    });

    test('multiplyToMinorUnits rounds once, after exact multiplication', () {
      expect(multiplyToMinorUnits(0.75, 9.99, 2), b(749)); // 7.4925
      expect(multiplyToMinorUnits(3, 19.99, 2), b(5997));
      expect(multiplyToMinorUnits(2.5, 40, 2), b(10000));
    });

    test('percentOf', () {
      expect(percentOf(b(63000), 13), b(8190));
      expect(percentOf(b(50), 13), b(7)); // 6.5 -> 7
      expect(percentOf(b(1000), 2.5), b(25));
      expect(percentOf(b(1000), 0), b(0));
    });

    test('minorUnitsToDouble', () {
      expect(minorUnitsToDouble(b(71190), 2), 711.9);
      expect(minorUnitsToDouble(b(5), 2), 0.05);
      expect(minorUnitsToDouble(b(-5), 2), -0.05);
      expect(minorUnitsToDouble(b(1001), 0), 1001);
      expect(minorUnitsToDouble(b(1), 3), 0.001);
    });
  });

  group('allocateProportionally', () {
    test('parts always sum to the amount', () {
      final parts = allocateProportionally(b(100), [b(1), b(1), b(1)]);
      expect(parts, [b(34), b(33), b(33)]);
    });

    test('proportional to weights', () {
      expect(
        allocateProportionally(b(30), [b(100), b(200)]),
        [b(10), b(20)],
      );
    });

    test('largest remainder gets the leftover unit', () {
      // 10 split by 1:2 -> 3.33 and 6.67 -> 3 and 7.
      expect(allocateProportionally(b(10), [b(1), b(2)]), [b(3), b(7)]);
    });

    test('all-zero weights give all-zero parts', () {
      expect(allocateProportionally(b(5), [b(0), b(0)]), [b(0), b(0)]);
    });
  });
}
