import 'package:meta/meta.dart';

import '../models/currency.dart';
import '../models/invoice_item.dart';
import '../models/tax.dart';

/// The calculated amounts for one [InvoiceItem].
///
/// All amounts are already rounded to the currency's decimal places.
@immutable
final class InvoiceLineTotals {
  /// Created by `InvoiceCalculator`. Not intended to be called directly.
  @internal
  const InvoiceLineTotals({
    required this.item,
    required this.grossAmount,
    required this.discountAmount,
    required this.lineTotal,
    required this.invoiceDiscountShare,
    required this.taxableAmount,
    required this.taxes,
  });

  /// The item these totals belong to.
  final InvoiceItem item;

  /// `quantity x unitPrice`.
  final double grossAmount;

  /// The item's own discount (0 when it has none).
  final double discountAmount;

  /// `grossAmount - discountAmount`. The amount shown in the "Total" column.
  final double lineTotal;

  /// This line's part of the invoice-level discount.
  final double invoiceDiscountShare;

  /// `lineTotal - invoiceDiscountShare`. Taxes are calculated on this.
  final double taxableAmount;

  /// Taxes applied to this line: the item's own taxes, or the invoice taxes.
  final List<Tax> taxes;

  @override
  String toString() => 'InvoiceLineTotals(${item.name}: $lineTotal)';
}

/// The calculated amount for one tax.
@immutable
final class InvoiceTaxLine {
  /// Created by `InvoiceCalculator`. Not intended to be called directly.
  @internal
  const InvoiceTaxLine({
    required this.tax,
    required this.taxableAmount,
    required this.amount,
  });

  /// The tax, for example VAT 13%.
  final Tax tax;

  /// The amount the tax was applied to.
  final double taxableAmount;

  /// The tax amount.
  final double amount;

  @override
  String toString() => 'InvoiceTaxLine(${tax.name}: $amount)';
}

/// All calculated amounts of an invoice. Created by
/// `InvoiceCalculator.calculate`.
///
/// ```text
///   subtotal          (sum of line totals)
/// - discountAmount    (invoice-level discount)
/// = taxableAmount
/// + taxAmount         (sum of taxLines)
/// = total
/// ```
///
/// Every value is rounded to [currency]'s decimal places, and the identities
/// above hold exactly. Use [totalInMinorUnits] when an API needs an integer
/// amount (cents), for example a payment gateway.
@immutable
final class InvoiceTotals {
  /// Created by `InvoiceCalculator`. Not intended to be called directly.
  @internal
  InvoiceTotals({
    required this.currency,
    required List<InvoiceLineTotals> lines,
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required List<InvoiceTaxLine> taxLines,
    required this.taxAmount,
    required this.total,
    required this.totalInMinorUnits,
  })  : lines = List.unmodifiable(lines),
        taxLines = List.unmodifiable(taxLines);

  /// The currency used for rounding.
  final Currency currency;

  /// One entry per invoice item, in the same order.
  final List<InvoiceLineTotals> lines;

  /// Sum of all line totals, before the invoice discount.
  final double subtotal;

  /// The invoice-level discount amount (0 when there is none).
  final double discountAmount;

  /// `subtotal - discountAmount`.
  final double taxableAmount;

  /// One entry per distinct tax, in order of first appearance.
  final List<InvoiceTaxLine> taxLines;

  /// Sum of all [taxLines] amounts.
  final double taxAmount;

  /// The grand total: `taxableAmount + taxAmount`.
  final double total;

  /// [total] as an integer number of minor units, for example cents.
  ///
  /// `711.90 USD` -> `71190`. For JPY (0 decimals) this equals [total].
  final int totalInMinorUnits;

  @override
  String toString() => 'InvoiceTotals(subtotal: $subtotal, '
      'discount: $discountAmount, tax: $taxAmount, total: $total '
      '${currency.code})';
}
