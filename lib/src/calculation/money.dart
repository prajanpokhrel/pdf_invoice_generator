// Internal exact-decimal helpers. Not exported.
//
// Why: `double` cannot store most decimal fractions exactly
// (0.1 + 0.2 == 0.30000000000000004, 1.005 * 100 == 100.49999999999999).
// We convert every input to an exact decimal (BigInt mantissa + scale) using
// Dart's shortest round-trip string form, so `1.005` really is 1.005. All
// math then happens on BigInt, which never overflows and behaves the same on
// the VM and on the Web (where `int` is only exact up to 2^53).

/// An exact decimal: `mantissa / 10^scale`.
final class ExactDecimal {
  /// Creates `mantissa / 10^scale`.
  const ExactDecimal(this.mantissa, this.scale);

  /// Converts [value] exactly. Throws [ArgumentError] for NaN or infinity.
  factory ExactDecimal.fromNum(num value) {
    if (value is int) return ExactDecimal(BigInt.from(value), 0);
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be a finite number');
    }
    // Shortest representation that round-trips, e.g. '1.005', '1e-7', '2.5e+21'.
    var text = value.toString();
    var exponent = 0;
    final e = text.indexOf('e');
    if (e != -1) {
      exponent = int.parse(text.substring(e + 1));
      text = text.substring(0, e);
    }
    var scale = 0;
    final dot = text.indexOf('.');
    if (dot != -1) {
      scale = text.length - dot - 1;
      text = text.replaceFirst('.', '');
    }
    var mantissa = BigInt.parse(text);
    scale -= exponent;
    if (scale < 0) {
      mantissa *= BigInt.from(10).pow(-scale);
      scale = 0;
    }
    return ExactDecimal(mantissa, scale);
  }

  /// All digits of the number, without the decimal point.
  final BigInt mantissa;

  /// How many of [mantissa]'s digits are after the decimal point.
  final int scale;
}

final BigInt _ten = BigInt.from(10);
final BigInt _hundred = BigInt.from(100);

BigInt _pow10(int n) => _ten.pow(n);

/// Divides [numerator] by a positive [denominator], rounding half away
/// from zero (0.5 -> 1, -0.5 -> -1, 0.49 -> 0).
BigInt roundDiv(BigInt numerator, BigInt denominator) {
  assert(denominator > BigInt.zero, 'denominator must be positive');
  final quotient = numerator ~/ denominator; // truncates toward zero
  final remainder = numerator.remainder(denominator);
  if (remainder.abs() * BigInt.two >= denominator) {
    return quotient + BigInt.from(numerator.sign);
  }
  return quotient;
}

/// [value] in minor units of a currency with [digits] decimals, rounded.
///
/// `toMinorUnits(12.345, 2) == 1235`.
BigInt toMinorUnits(num value, int digits) {
  final d = ExactDecimal.fromNum(value);
  return roundDiv(d.mantissa * _pow10(digits), _pow10(d.scale));
}

/// `quantity * unitPrice` in minor units, computed exactly then rounded once.
BigInt multiplyToMinorUnits(num quantity, num unitPrice, int digits) {
  final q = ExactDecimal.fromNum(quantity);
  final p = ExactDecimal.fromNum(unitPrice);
  return roundDiv(
    q.mantissa * p.mantissa * _pow10(digits),
    _pow10(q.scale + p.scale),
  );
}

/// [percent]% of [minorUnits], rounded to a whole minor unit.
///
/// `percentOf(BigInt.from(63000), 13) == 8190`.
BigInt percentOf(BigInt minorUnits, num percent) {
  final p = ExactDecimal.fromNum(percent);
  return roundDiv(minorUnits * p.mantissa, _hundred * _pow10(p.scale));
}

/// Converts minor units back to a `double` in major units.
///
/// Goes through a decimal string, so the result is the double closest to
/// the exact value (63000 cents -> 630.0, 8190 -> 81.9).
double minorUnitsToDouble(BigInt minorUnits, int digits) {
  if (digits == 0) return minorUnits.toDouble();
  final negative = minorUnits.isNegative;
  final digitsText = minorUnits.abs().toString().padLeft(digits + 1, '0');
  final split = digitsText.length - digits;
  final text = '${negative ? '-' : ''}${digitsText.substring(0, split)}.'
      '${digitsText.substring(split)}';
  return double.parse(text);
}

/// Splits [amount] across [weights] in proportion, so that the parts always
/// add up to exactly [amount] (largest remainder method).
///
/// Each part is first rounded down; the units left over go to the parts with
/// the largest remainders (ties go to the earlier index). All inputs must be
/// non-negative. If every weight is zero, every part is zero.
List<BigInt> allocateProportionally(BigInt amount, List<BigInt> weights) {
  final total = weights.fold(BigInt.zero, (a, b) => a + b);
  if (total == BigInt.zero || amount == BigInt.zero) {
    return List.filled(weights.length, BigInt.zero);
  }
  final parts = <BigInt>[];
  final remainders = <BigInt>[];
  for (final w in weights) {
    final numerator = amount * w;
    parts.add(numerator ~/ total);
    remainders.add(numerator.remainder(total));
  }
  var leftover = amount - parts.fold(BigInt.zero, (a, b) => a + b);
  final order = List.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = remainders[b].compareTo(remainders[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (final i in order) {
    if (leftover <= BigInt.zero) break;
    parts[i] += BigInt.one;
    leftover -= BigInt.one;
  }
  return parts;
}
