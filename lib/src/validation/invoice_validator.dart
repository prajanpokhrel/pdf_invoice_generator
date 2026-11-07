import '../calculation/money.dart';
import '../calculation/totals_engine.dart';
import '../exceptions/invoice_exceptions.dart';
import '../models/discount.dart';
import '../models/invoice.dart';
import '../models/tax.dart';

/// Checks an [Invoice] for data that would produce a wrong or broken invoice.
///
/// `InvoiceCalculator.calculate` and the PDF generator run this
/// automatically, so you only need it directly to show errors early, for
/// example in a form:
///
/// ```dart
/// final issues = InvoiceValidator.validate(invoice);
/// for (final issue in issues) {
///   print('${issue.field}: ${issue.message}');
/// }
/// ```
///
/// Rules:
/// * `invoiceNumber`, `seller.name`, `customer.name` and every item name
///   must not be blank.
/// * There must be at least one item.
/// * `dueDate`, when set, must not be before `issueDate`.
/// * Quantities and unit prices must be finite and not negative
///   (zero is allowed).
/// * Tax percentages must be between 0 and 100, tax names must not be blank,
///   and the same tax must not be listed twice.
/// * Percentage discounts must be between 0 and 100; fixed discounts must
///   not be negative and not larger than the amount they apply to.
/// * The total must not exceed 10^15 minor units (10 trillion USD), the
///   largest amount that every platform can represent exactly.
abstract final class InvoiceValidator {
  /// Largest supported amount, in minor units.
  static final BigInt _maxMinorUnits = BigInt.from(10).pow(15);

  /// Returns every problem found in [invoice]. Empty means valid.
  static List<InvoiceValidationIssue> validate(Invoice invoice) {
    final issues = <InvoiceValidationIssue>[];
    void add(String field, String message) =>
        issues.add(InvoiceValidationIssue(field, message));

    // --- Required text -----------------------------------------------------
    if (invoice.invoiceNumber.trim().isEmpty) {
      add('invoiceNumber', 'must not be empty');
    }
    if (invoice.seller.name.trim().isEmpty) {
      add('seller.name', 'must not be empty');
    }
    if (invoice.customer.name.trim().isEmpty) {
      add('customer.name', 'must not be empty');
    }

    // --- Dates -------------------------------------------------------------
    final dueDate = invoice.dueDate;
    if (dueDate != null && dueDate.isBefore(invoice.issueDate)) {
      add('dueDate', 'must not be before issueDate');
    }

    // --- Items -------------------------------------------------------------
    if (invoice.items.isEmpty) add('items', 'must contain at least one item');
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final path = 'items[$i]';
      if (item.name.trim().isEmpty) add('$path.name', 'must not be empty');
      _checkNonNegative(item.quantity, '$path.quantity', add);
      _checkNonNegative(item.unitPrice, '$path.unitPrice', add);
      _checkDiscount(item.discount, '$path.discount', add);
      if (item.taxes != null) _checkTaxes(item.taxes!, '$path.taxes', add);
    }

    // --- Invoice-level tax and discount ------------------------------------
    _checkTaxes(invoice.taxes, 'taxes', add);
    _checkDiscount(invoice.discount, 'discount', add);

    // --- Rules that need the calculated amounts ----------------------------
    // Only safe to compute once every number is known to be valid.
    if (issues.isEmpty) _checkAmounts(invoice, add);

    return List.unmodifiable(issues);
  }

  /// Throws an [InvoiceValidationException] listing every problem, or
  /// returns normally when [invoice] is valid.
  static void ensureValid(Invoice invoice) {
    final issues = validate(invoice);
    if (issues.isNotEmpty) throw InvoiceValidationException(issues);
  }

  static void _checkNonNegative(
    num value,
    String field,
    void Function(String, String) add,
  ) {
    if (!value.isFinite) {
      add(field, 'must be a finite number (got $value)');
    } else if (value < 0) {
      add(field, 'must not be negative (got $value)');
    }
  }

  static void _checkPercentage(
    num value,
    String field,
    void Function(String, String) add,
  ) {
    if (!value.isFinite || value < 0 || value > 100) {
      add(field, 'must be between 0 and 100 (got $value)');
    }
  }

  static void _checkDiscount(
    Discount? discount,
    String field,
    void Function(String, String) add,
  ) {
    if (discount == null) return;
    switch (discount.type) {
      case DiscountType.percentage:
        _checkPercentage(discount.value, '$field.value', add);
      case DiscountType.fixed:
        _checkNonNegative(discount.value, '$field.value', add);
    }
  }

  static void _checkTaxes(
    List<Tax> taxes,
    String field,
    void Function(String, String) add,
  ) {
    final seen = <Tax>{};
    for (var i = 0; i < taxes.length; i++) {
      final tax = taxes[i];
      if (tax.name.trim().isEmpty) add('$field[$i].name', 'must not be empty');
      _checkPercentage(tax.percentage, '$field[$i].percentage', add);
      if (!seen.add(tax)) {
        add('$field[$i]', '${tax.name} ${tax.percentage}% is listed twice');
      }
    }
  }

  static void _checkAmounts(
    Invoice invoice,
    void Function(String, String) add,
  ) {
    final digits = invoice.currency.decimalDigits;
    String money(BigInt minor) =>
        minorUnitsToDouble(minor, digits).toStringAsFixed(digits);

    final raw = computeTotals(invoice);
    var lineDiscountTooLarge = false;
    for (var i = 0; i < raw.lines.length; i++) {
      final line = raw.lines[i];
      if (line.net < BigInt.zero) {
        lineDiscountTooLarge = true;
        add(
          'items[$i].discount.value',
          'discount (${money(line.discount)}) is larger than the line '
              'amount (${money(line.gross)})',
        );
      }
    }
    // A negative line makes the subtotal wrong too. Report only the root
    // cause instead of a confusing follow-up error on the invoice discount.
    if (!lineDiscountTooLarge && raw.taxable < BigInt.zero) {
      add(
        'discount.value',
        'discount (${money(raw.discount)}) is larger than the subtotal '
            '(${money(raw.subtotal)})',
      );
    }
    final largest = [
      for (final l in raw.lines) l.gross,
      raw.subtotal,
      raw.total,
    ].fold(BigInt.zero, (a, b) => b > a ? b : a);
    if (largest > _maxMinorUnits) {
      add(
        'total',
        'is too large to be represented exactly (max '
            '${money(_maxMinorUnits)} ${invoice.currency.code})',
      );
    }
  }
}
