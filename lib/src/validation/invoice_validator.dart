import 'package:pdf/widgets.dart' show Barcode;

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
/// * The currency needs a code and 0 to 6 decimal digits.
/// * `dueDate`, when set, must not be on a day before `issueDate`.
/// * Item `name`, `unit` and `sku` are limited to [maxItemNameLength],
///   [maxUnitLength] and [maxSkuLength] characters, and an item has at most
///   [maxTaxesPerItem] taxes, because each item row must fit on one page.
///   Long text belongs in `description`, which may be any length.
/// * Quantities and unit prices must be finite and not negative
///   (zero is allowed).
/// * Tax percentages must be between 0 and 100, tax names must not be blank,
///   and the same tax must not be listed twice.
/// * Percentage discounts must be between 0 and 100; fixed discounts must
///   not be negative and not larger than the amount they apply to.
/// * A QR code, when set, must have non-empty data short enough to encode.
/// * The total must not exceed 10^15 minor units (10 trillion USD), the
///   largest amount that every platform can represent exactly.
abstract final class InvoiceValidator {
  /// Largest supported amount, in minor units.
  static final BigInt _maxMinorUnits = BigInt.from(10).pow(15);

  /// Longest allowed item name, in characters.
  static const int maxItemNameLength = 300;

  /// Longest allowed item unit (for example `hrs`), in characters.
  static const int maxUnitLength = 30;

  /// Longest allowed item SKU, in characters.
  static const int maxSkuLength = 100;

  /// Most taxes a single item may have.
  static const int maxTaxesPerItem = 10;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static void _checkLength(
    String? value,
    int max,
    String field,
    void Function(String, String) add, {
    String? hint,
  }) {
    if (value == null || value.length <= max) return;
    add(
      field,
      'must be at most $max characters (got ${value.length})'
      '${hint == null ? '' : '; $hint'}',
    );
  }

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

    // --- Currency ----------------------------------------------------------
    // Also checked by an assert in Currency's constructor, but asserts are
    // removed in release builds.
    final currency = invoice.currency;
    if (currency.code.trim().isEmpty) add('currency.code', 'must not be empty');
    if (currency.decimalDigits < 0 || currency.decimalDigits > 6) {
      add(
        'currency.decimalDigits',
        'must be between 0 and 6 (got ${currency.decimalDigits})',
      );
    }

    // --- Dates -------------------------------------------------------------
    // Compare calendar days, not exact times: an invoice issued with
    // DateTime.now() may be due "today" (midnight is earlier than now).
    final dueDate = invoice.dueDate;
    if (dueDate != null && _day(dueDate).isBefore(_day(invoice.issueDate))) {
      add('dueDate', 'must not be before issueDate');
    }

    // --- Items -------------------------------------------------------------
    if (invoice.items.isEmpty) add('items', 'must contain at least one item');
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final path = 'items[$i]';
      if (item.name.trim().isEmpty) add('$path.name', 'must not be empty');
      // These print inside one table row, which cannot be split across
      // pages, so their length is limited. Long text belongs in
      // `description`, which continues over several rows.
      _checkLength(
        item.name,
        maxItemNameLength,
        '$path.name',
        add,
        hint: 'put long text in description',
      );
      _checkLength(item.unit, maxUnitLength, '$path.unit', add);
      _checkLength(item.sku, maxSkuLength, '$path.sku', add);
      if (item.taxes != null && item.taxes!.length > maxTaxesPerItem) {
        add('$path.taxes', 'must contain at most $maxTaxesPerItem taxes');
      }
      _checkNonNegative(item.quantity, '$path.quantity', add);
      _checkNonNegative(item.unitPrice, '$path.unitPrice', add);
      _checkDiscount(item.discount, '$path.discount', add);
      if (item.taxes != null) _checkTaxes(item.taxes!, '$path.taxes', add);
    }

    // --- Invoice-level tax and discount ------------------------------------
    _checkTaxes(invoice.taxes, 'taxes', add);
    _checkDiscount(invoice.discount, 'discount', add);

    // --- QR code -----------------------------------------------------------
    final qr = invoice.qrCode;
    if (qr != null) {
      if (qr.data.trim().isEmpty) {
        add('qrCode.data', 'must not be empty');
      } else if (!Barcode.qrCode().isValid(qr.data)) {
        add('qrCode.data', 'is too long to fit in a QR code');
      }
    }

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
