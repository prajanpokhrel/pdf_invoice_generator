// Internal: the actual invoice math, in exact minor units. Not exported.
//
// The engine assumes basic validation already passed (finite, non-negative
// numbers). It does NOT clamp results, so the validator can inspect the raw
// output and report, for example, a fixed discount larger than the subtotal.

import '../models/discount.dart';
import '../models/invoice.dart';
import '../models/tax.dart';
import 'money.dart';

/// Raw result for one invoice line, in minor units.
final class RawLine {
  /// Creates a raw line.
  RawLine({
    required this.gross,
    required this.discount,
    required this.taxes,
  });

  /// quantity x unitPrice, rounded.
  final BigInt gross;

  /// Item-level discount.
  final BigInt discount;

  /// Taxes that apply to this line (item taxes or the invoice taxes).
  final List<Tax> taxes;

  /// gross - item discount. This is the "line total" printed on the invoice.
  BigInt get net => gross - discount;

  /// This line's share of the invoice-level discount.
  BigInt invoiceDiscountShare = BigInt.zero;

  /// net - share of invoice discount. The amount taxes are applied to.
  BigInt get taxable => net - invoiceDiscountShare;
}

/// Raw result for one tax, in minor units.
final class RawTax {
  /// Creates a raw tax line for [tax].
  RawTax(this.tax);

  /// The tax.
  final Tax tax;

  /// Sum of the taxable amounts of all lines this tax applies to.
  BigInt base = BigInt.zero;

  /// [tax] percentage of [base], rounded once.
  BigInt amount = BigInt.zero;
}

/// Raw invoice totals, in minor units.
final class RawTotals {
  /// Creates raw totals.
  RawTotals({
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.taxes,
  });

  /// One entry per invoice item, same order.
  final List<RawLine> lines;

  /// Sum of line nets.
  final BigInt subtotal;

  /// Invoice-level discount.
  final BigInt discount;

  /// One entry per distinct tax, in order of first appearance.
  final List<RawTax> taxes;

  /// subtotal - discount.
  BigInt get taxable => subtotal - discount;

  /// Sum of all tax amounts.
  BigInt get taxAmount => taxes.fold(BigInt.zero, (a, t) => a + t.amount);

  /// taxable + taxAmount.
  BigInt get total => taxable + taxAmount;
}

BigInt _discountAmount(Discount? discount, BigInt base, int digits) {
  if (discount == null) return BigInt.zero;
  return switch (discount.type) {
    DiscountType.percentage => percentOf(base, discount.value),
    DiscountType.fixed => toMinorUnits(discount.value, digits),
  };
}

/// Computes all totals for [invoice]. See `InvoiceCalculator` for the rules.
RawTotals computeTotals(Invoice invoice) {
  final digits = invoice.currency.decimalDigits;

  // 1. Lines: gross, item discount, net.
  final lines = [
    for (final item in invoice.items)
      () {
        final gross =
            multiplyToMinorUnits(item.quantity, item.unitPrice, digits);
        return RawLine(
          gross: gross,
          discount: _discountAmount(item.discount, gross, digits),
          taxes: item.taxes ?? invoice.taxes,
        );
      }(),
  ];

  // 2. Subtotal and invoice discount.
  final subtotal = lines.fold(BigInt.zero, (a, l) => a + l.net);
  final discount = _discountAmount(invoice.discount, subtotal, digits);

  // 3. Share the invoice discount across lines so each line knows its
  //    taxable amount. Needed when items have different tax rates.
  //    Negative nets only happen with invalid input; treat them as zero
  //    weight so the allocation itself never fails.
  final shares = allocateProportionally(
    discount < BigInt.zero ? BigInt.zero : discount,
    [for (final l in lines) l.net < BigInt.zero ? BigInt.zero : l.net],
  );
  for (var i = 0; i < lines.length; i++) {
    lines[i].invoiceDiscountShare = shares[i];
  }

  // 4. Taxes: group lines by tax, round once per tax.
  final taxes = <Tax, RawTax>{};
  for (final line in lines) {
    for (final tax in line.taxes) {
      taxes.putIfAbsent(tax, () => RawTax(tax)).base += line.taxable;
    }
  }
  for (final t in taxes.values) {
    t.amount = percentOf(t.base, t.tax.percentage);
  }

  return RawTotals(
    lines: lines,
    subtotal: subtotal,
    discount: discount,
    taxes: taxes.values.toList(),
  );
}
