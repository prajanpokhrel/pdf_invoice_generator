import 'package:meta/meta.dart';

/// Base class for every error thrown by this package.
///
/// Catch this to handle all invoice errors in one place:
///
/// ```dart
/// try {
///   await InvoiceGenerator.generate(invoice);
/// } on InvoiceValidationException catch (e) {
///   print(e.issues); // what is wrong with the data
/// } on InvoiceException catch (e) {
///   print(e.message); // anything else
/// }
/// ```
///
/// New subclasses may be added in future versions, so a `switch` over
/// exception types should always keep a fallback case.
abstract class InvoiceException implements Exception {
  /// Creates an exception with a human-readable [message].
  const InvoiceException(this.message, {this.cause});

  /// What went wrong, in plain language.
  final String message;

  /// The underlying error, if this exception wraps another one.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (cause != null) buffer.write(' (cause: $cause)');
    return buffer.toString();
  }
}

/// One problem found while validating an invoice.
@immutable
final class InvoiceValidationIssue {
  /// Creates an issue for [field] described by [message].
  const InvoiceValidationIssue(this.field, this.message);

  /// Path of the invalid value, for example `items[2].quantity`.
  final String field;

  /// What is wrong, for example `must not be negative`.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is InvoiceValidationIssue &&
      other.field == field &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => '$field: $message';
}

/// The invoice data is invalid, for example a negative price or a tax
/// above 100%.
///
/// [issues] lists *every* problem found, so they can all be fixed at once.
final class InvoiceValidationException extends InvoiceException {
  /// Creates the exception from a non-empty list of [issues].
  InvoiceValidationException(List<InvoiceValidationIssue> issues)
      : issues = List.unmodifiable(issues),
        super(_describe(issues));

  /// All problems found.
  final List<InvoiceValidationIssue> issues;

  static String _describe(List<InvoiceValidationIssue> issues) {
    final count = issues.length;
    final header = 'Invoice is invalid ($count '
        '${count == 1 ? 'problem' : 'problems'})';
    return [header, ...issues.map((i) => '- $i')].join('\n');
  }
}

/// The logo could not be loaded or decoded (missing asset, network error,
/// unsupported or corrupt image).
final class InvoiceImageException extends InvoiceException {
  /// Creates the exception.
  const InvoiceImageException(super.message, {super.cause});
}

/// The PDF could not be built for a reason other than invalid data or a bad
/// image.
final class InvoiceGenerationException extends InvoiceException {
  /// Creates the exception.
  const InvoiceGenerationException(
    super.message, {
    super.cause,
    this.stackTrace,
  });

  /// Stack trace of [cause], when available.
  final StackTrace? stackTrace;
}

/// Saving, sharing or printing failed on this platform, for example because
/// the plugin is not available (an app that was hot-restarted instead of
/// rebuilt after adding the package) or the file could not be written.
final class InvoiceOutputException extends InvoiceException {
  /// Creates the exception.
  const InvoiceOutputException(super.message, {super.cause});
}
