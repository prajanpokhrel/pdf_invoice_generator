import 'package:meta/meta.dart';

import '../utils/equality.dart';
import '../utils/tax_merge.dart';
import 'discount.dart';
import 'tax.dart';

/// One line on the invoice.
///
/// [quantity] may be fractional (for example `2.5` hours or `0.75` kg).
///
/// ```dart
/// InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100)
/// ```
///
/// ### Item-level tax
/// * Leave [taxes] unset (`null`) to use the invoice's taxes. This is the
///   common case.
/// * Pass `tax:` or `taxes:` to tax this item differently.
/// * Pass `taxes: const []` to make this item tax-exempt.
@immutable
final class InvoiceItem {
  /// Creates an invoice line.
  ///
  /// Pass either [tax] or [taxes], not both. Passing both throws an
  /// [ArgumentError].
  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.description,
    this.sku,
    this.unit,
    this.discount,
    Tax? tax,
    List<Tax>? taxes,
  }) : taxes = mergeTaxes(tax, taxes);

  /// Short name of the product or service.
  final String name;

  /// How many units. Fractions are allowed; must not be negative.
  final num quantity;

  /// Price of one unit, before discount and tax. Must not be negative.
  final num unitPrice;

  /// Longer description printed under or next to [name].
  final String? description;

  /// Stock keeping unit / product code.
  final String? sku;

  /// Unit label, for example `hrs`, `kg` or `pcs`.
  final String? unit;

  /// Discount applied to this line only, before the invoice discount.
  final Discount? discount;

  /// Taxes for this line.
  ///
  /// `null` means "use the invoice taxes". An empty list means tax-exempt.
  final List<Tax>? taxes;

  /// Returns a copy with the given fields replaced.
  ///
  /// Like all `copyWith` methods in this package, passing `null` keeps the
  /// current value. To remove an optional value, create a new item.
  InvoiceItem copyWith({
    String? name,
    num? quantity,
    num? unitPrice,
    String? description,
    String? sku,
    String? unit,
    Discount? discount,
    List<Tax>? taxes,
  }) {
    return InvoiceItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      discount: discount ?? this.discount,
      taxes: taxes ?? this.taxes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InvoiceItem &&
      other.name == name &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice &&
      other.description == description &&
      other.sku == sku &&
      other.unit == unit &&
      other.discount == discount &&
      listEquals(other.taxes, taxes);

  @override
  int get hashCode => Object.hash(
        name,
        quantity,
        unitPrice,
        description,
        sku,
        unit,
        discount,
        taxes == null ? null : Object.hashAll(taxes!),
      );

  @override
  String toString() => 'InvoiceItem($name, $quantity x $unitPrice)';
}
