import 'package:meta/meta.dart';

/// Internal identifier of a built-in template.
@internal
enum TemplateId {
  /// See [InvoiceTemplate.classic].
  classic,

  /// See [InvoiceTemplate.modern].
  modern,

  /// See [InvoiceTemplate.minimal].
  minimal,
}

/// The layout style of the generated PDF.
///
/// ```dart
/// await InvoiceGenerator.generate(invoice, template: InvoiceTemplate.modern);
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

  /// Modern startup/SaaS style: coloured header band, highlighted amount
  /// due, striped table without grid lines and a rounded summary card.
  static const modern = InvoiceTemplate._(TemplateId.modern, 'modern');

  /// Simple and clean: no fills, thin lines and generous white space.
  static const minimal = InvoiceTemplate._(TemplateId.minimal, 'minimal');

  /// All built-in templates, useful for pickers.
  static const List<InvoiceTemplate> values = [classic, modern, minimal];

  /// Internal identifier.
  @internal
  final TemplateId id;

  /// Lower-case name, for example `classic`.
  final String name;

  @override
  String toString() => 'InvoiceTemplate.$name';
}
