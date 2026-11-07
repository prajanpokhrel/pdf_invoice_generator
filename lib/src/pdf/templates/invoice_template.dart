import 'package:meta/meta.dart';

/// Internal identifier of a built-in template.
@internal
enum TemplateId {
  /// See [InvoiceTemplate.classic].
  classic,
}

/// The layout style of the generated PDF.
///
/// ```dart
/// await InvoiceGenerator.generate(invoice, template: InvoiceTemplate.classic);
/// ```
///
/// Templates only change how the invoice looks; the data and the totals are
/// identical for every template.
@immutable
final class InvoiceTemplate {
  const InvoiceTemplate._(this.id, this.name);

  /// Traditional professional invoice: logo and seller on the left,
  /// a large title on the right, bordered table with a coloured header.
  static const classic = InvoiceTemplate._(TemplateId.classic, 'classic');

  /// All built-in templates, useful for pickers.
  static const List<InvoiceTemplate> values = [classic];

  /// Internal identifier.
  @internal
  final TemplateId id;

  /// Lower-case name, for example `classic`.
  final String name;

  @override
  String toString() => 'InvoiceTemplate.$name';
}
