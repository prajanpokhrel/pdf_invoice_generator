import 'package:meta/meta.dart';

/// A tax applied as a percentage, such as VAT, GST or sales tax.
///
/// The package has no built-in country rules. It applies exactly the
/// [percentage] you provide.
///
/// ```dart
/// const vat = Tax(name: 'VAT', percentage: 13);
/// ```
@immutable
final class Tax {
  /// Creates a tax.
  ///
  /// [percentage] is a value such as `13` for 13%. It is checked to be
  /// between 0 and 100 when the invoice is validated.
  const Tax({required this.name, required this.percentage});

  /// Label printed on the invoice, for example `VAT` or `GST`.
  final String name;

  /// Rate in percent, for example `13` means 13%.
  final num percentage;

  /// Returns a copy with the given fields replaced.
  Tax copyWith({String? name, num? percentage}) => Tax(
        name: name ?? this.name,
        percentage: percentage ?? this.percentage,
      );

  @override
  bool operator ==(Object other) =>
      other is Tax && other.name == name && other.percentage == percentage;

  @override
  int get hashCode => Object.hash(name, percentage);

  @override
  String toString() => 'Tax($name, $percentage%)';
}
