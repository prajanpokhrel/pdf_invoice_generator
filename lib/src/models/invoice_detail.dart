import 'package:meta/meta.dart';

/// An extra label/value row printed in the invoice header, next to the
/// invoice number and dates.
///
/// ```dart
/// const InvoiceDetail(label: 'PO Number', value: 'PO-7781')
/// ```
@immutable
final class InvoiceDetail {
  /// Creates a detail row.
  const InvoiceDetail({required this.label, required this.value});

  /// Left side, for example `PO Number`.
  final String label;

  /// Right side, for example `PO-7781`.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is InvoiceDetail && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'InvoiceDetail($label: $value)';
}
