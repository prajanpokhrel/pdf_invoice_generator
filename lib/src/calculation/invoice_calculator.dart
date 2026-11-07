import '../models/invoice.dart';
import '../validation/invoice_validator.dart';
import 'invoice_totals.dart';
import 'money.dart';
import 'totals_engine.dart';

/// Calculates the totals of an [Invoice].
///
/// ```dart
/// final totals = InvoiceCalculator.calculate(invoice);
/// print(totals.total); // 711.9
/// ```
///
/// ## Order of operations
/// ```text
/// line total     = quantity x unitPrice - item discount
/// subtotal       = sum of line totals
/// discount       = invoice discount applied to subtotal
/// taxable amount = subtotal - discount
/// tax            = each tax % of the taxable amount it applies to
/// total          = taxable amount + all taxes
/// ```
///
/// ## Precision and rounding
/// * Every input number is read as the exact decimal it prints as, and all
///   math is done on integers. So a price of `1.005` is exactly 1.005
///   (a `double` would hold 1.00499999...), and summing many lines never
///   accumulates floating-point error.
/// * Amounts are rounded to the currency's `Currency.decimalDigits`
///   (2 for USD, 0 for JPY) using **round half away from zero**:
///   `0.125 -> 0.13`, `0.124 -> 0.12`.
/// * Rounding happens once per value: each `quantity x unitPrice`, each
///   discount, and each tax (per tax rate, on the summed taxable amount,
///   not per line). Subtotal, taxable amount and total are exact sums of
///   rounded values, so the printed numbers always add up.
///
/// ## Items with different taxes
/// When items have their own taxes, the invoice discount is shared across
/// lines in proportion to their line totals, so each tax is applied to the
/// correct discounted base. The shares always add up exactly to the
/// discount (largest remainder method).
///
/// Taxes are applied to the discounted amount and are never compounded
/// (a tax is never charged on another tax).
abstract final class InvoiceCalculator {
  /// Validates [invoice] and calculates its totals.
  ///
  /// Throws an `InvoiceValidationException` when the invoice is invalid
  /// (see [InvoiceValidator]).
  static InvoiceTotals calculate(Invoice invoice) {
    InvoiceValidator.ensureValid(invoice);

    final digits = invoice.currency.decimalDigits;
    double amount(BigInt minor) => minorUnitsToDouble(minor, digits);
    final raw = computeTotals(invoice);

    return InvoiceTotals(
      currency: invoice.currency,
      lines: [
        for (var i = 0; i < raw.lines.length; i++)
          InvoiceLineTotals(
            item: invoice.items[i],
            grossAmount: amount(raw.lines[i].gross),
            discountAmount: amount(raw.lines[i].discount),
            lineTotal: amount(raw.lines[i].net),
            invoiceDiscountShare: amount(raw.lines[i].invoiceDiscountShare),
            taxableAmount: amount(raw.lines[i].taxable),
            taxes: List.unmodifiable(raw.lines[i].taxes),
          ),
      ],
      subtotal: amount(raw.subtotal),
      discountAmount: amount(raw.discount),
      taxableAmount: amount(raw.taxable),
      taxLines: [
        for (final t in raw.taxes)
          InvoiceTaxLine(
            tax: t.tax,
            taxableAmount: amount(t.base),
            amount: amount(t.amount),
          ),
      ],
      taxAmount: amount(raw.taxAmount),
      total: amount(raw.total),
      totalInMinorUnits: raw.total.toInt(),
    );
  }
}
