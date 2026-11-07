import 'package:meta/meta.dart';

/// How a [Discount] value is interpreted.
enum DiscountType {
  /// The value is a percentage, for example `10` means 10% off.
  percentage,

  /// The value is a fixed amount in the invoice currency, for example `50`.
  fixed,
}

/// A discount on a single item or on the whole invoice.
///
/// ```dart
/// const tenPercent = Discount.percentage(10);
/// const fiftyOff = Discount.fixed(50);
/// // Equivalent long form:
/// const same = Discount(type: DiscountType.percentage, value: 10);
/// ```
@immutable
final class Discount {
  /// Creates a discount of the given [type].
  const Discount({required this.type, required this.value, this.label});

  /// A percentage discount, for example `Discount.percentage(10)` for 10% off.
  const Discount.percentage(this.value, {this.label})
      : type = DiscountType.percentage;

  /// A fixed-amount discount, for example `Discount.fixed(50)`.
  const Discount.fixed(this.value, {this.label}) : type = DiscountType.fixed;

  /// Whether [value] is a percentage or a fixed amount.
  final DiscountType type;

  /// The percentage (0-100) or the fixed amount, depending on [type].
  final num value;

  /// Optional label printed on the invoice, for example `Loyalty discount`.
  final String? label;

  /// Returns a copy with the given fields replaced.
  Discount copyWith({DiscountType? type, num? value, String? label}) =>
      Discount(
        type: type ?? this.type,
        value: value ?? this.value,
        label: label ?? this.label,
      );

  @override
  bool operator ==(Object other) =>
      other is Discount &&
      other.type == type &&
      other.value == value &&
      other.label == label;

  @override
  int get hashCode => Object.hash(type, value, label);

  @override
  String toString() => 'Discount(${type.name}, $value)';
}
