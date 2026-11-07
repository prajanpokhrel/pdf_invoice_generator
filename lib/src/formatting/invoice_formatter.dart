import 'package:intl/intl.dart';

import '../calculation/money.dart';
import '../models/currency.dart';

/// Formats money, quantities, percentages and dates the same way the PDF
/// does. Useful to show matching values in your own UI.
///
/// ```dart
/// final f = InvoiceFormatter(currency: Currency.usd);
/// f.money(1234.5);            // $1,234.50
/// f.quantity(2.5);            // 2.5
/// f.percent(13);              // 13%
/// f.date(DateTime(2026, 11, 7)); // Nov 7, 2026
/// ```
///
/// [locale] controls separators (`1.234,50` for `de_DE`). Number formats
/// work for every locale out of the box. Date formats for locales other than
/// `en_US` need `initializeDateFormatting()` from
/// `package:intl/date_symbol_data_local.dart` to be called once at startup.
final class InvoiceFormatter {
  /// Creates a formatter.
  ///
  /// Throws an [ArgumentError] when [locale] is not a known locale. Date data
  /// is only checked the first time [date] is called, so money can be
  /// formatted in any known locale without loading date data.
  factory InvoiceFormatter({
    required Currency currency,
    String locale = 'en_US',
    String datePattern = 'MMM d, yyyy',
  }) {
    try {
      return InvoiceFormatter._(
        currency,
        locale,
        datePattern,
        NumberFormat.decimalPatternDigits(
          locale: locale,
          decimalDigits: currency.decimalDigits,
        ),
        NumberFormat('#,##0.####', locale),
        NumberFormat('#,##0.##', locale),
      );
    } on ArgumentError catch (e) {
      throw ArgumentError(
        'Locale "$locale" is not supported for number formatting '
        '(${e.message}). Use a locale such as "en_US", "de_DE" or "hi_IN".',
      );
    }
  }

  InvoiceFormatter._(
    this.currency,
    this.locale,
    this.datePattern,
    this._money,
    this._quantity,
    this._percent,
  );

  /// Currency used by [money].
  final Currency currency;

  /// Locale used for separators and month names, for example `en_US`.
  final String locale;

  /// Date pattern, for example `MMM d, yyyy` or `dd/MM/yyyy`.
  /// See `DateFormat` in package:intl for the syntax.
  final String datePattern;

  final NumberFormat _money;
  final NumberFormat _quantity;
  final NumberFormat _percent;
  late final DateFormat _date = _createDateFormat(datePattern, locale);

  static DateFormat _createDateFormat(String pattern, String locale) {
    try {
      return DateFormat(pattern, locale);
    } on Object catch (e) {
      throw ArgumentError(
        'Date formatting for locale "$locale" is not available ($e). '
        'Call initializeDateFormatting("$locale") from '
        'package:intl/date_symbol_data_local.dart before generating, '
        'or use the default locale "en_US".',
      );
    }
  }

  /// Formats [amount] with the currency symbol, for example `$1,234.50`,
  /// `Rs. 1,234.50` or `-$5.00`.
  ///
  /// The amount is rounded exactly like `InvoiceCalculator` does (half away
  /// from zero on the exact decimal value), so `1.005` shows as `$1.01`,
  /// matching the calculated totals. Throws an [ArgumentError] for NaN or
  /// infinity.
  String money(num amount) {
    final places = currency.decimalDigits;
    final rounded = minorUnitsToDouble(toMinorUnits(amount, places), places);
    final digits = _money.format(rounded.abs());
    final space = currency.spaceBetweenSymbolAndAmount ? ' ' : '';
    final body = currency.symbolBeforeAmount
        ? '${currency.symbol}$space$digits'
        : '$digits$space${currency.symbol}';
    return rounded < 0 ? '-$body' : body;
  }

  /// Formats a quantity with up to 4 decimals, for example `2.5` or `1,000`.
  String quantity(num value) => _quantity.format(value);

  /// Formats a percentage, for example `13%` or `2.5%`.
  String percent(num value) => '${_percent.format(value)}%';

  /// Formats [value] using [datePattern].
  ///
  /// Throws an [ArgumentError] when date data for [locale] is not loaded.
  String date(DateTime value) => _date.format(value);
}
