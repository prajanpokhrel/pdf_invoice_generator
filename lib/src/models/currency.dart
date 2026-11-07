import 'package:meta/meta.dart';

/// Describes how money is displayed: its code, symbol and decimal places.
///
/// A currency never converts amounts. It only controls formatting and the
/// precision used when rounding (for example 2 decimals for USD, 0 for JPY).
///
/// Use a built-in constant such as [Currency.usd], or create your own:
///
/// ```dart
/// const npr = Currency(code: 'NPR', symbol: 'Rs.', decimalDigits: 2);
/// ```
@immutable
final class Currency {
  /// Creates a currency.
  ///
  /// [decimalDigits] must be between 0 and 6.
  const Currency({
    required this.code,
    required this.symbol,
    this.decimalDigits = 2,
    this.symbolBeforeAmount = true,
    this.spaceBetweenSymbolAndAmount = false,
    this.name,
  }) : assert(
          decimalDigits >= 0 && decimalDigits <= 6,
          'decimalDigits must be between 0 and 6',
        );

  /// United States dollar.
  static const usd = Currency(code: 'USD', symbol: r'$', name: 'US Dollar');

  /// Euro.
  static const eur = Currency(code: 'EUR', symbol: '€', name: 'Euro');

  /// British pound sterling.
  static const gbp = Currency(code: 'GBP', symbol: '£', name: 'British Pound');

  /// Indian rupee.
  static const inr = Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee');

  /// Nepalese rupee.
  static const npr = Currency(
    code: 'NPR',
    symbol: 'Rs.',
    spaceBetweenSymbolAndAmount: true,
    name: 'Nepalese Rupee',
  );

  /// Australian dollar.
  static const aud = Currency(
    code: 'AUD',
    symbol: r'A$',
    name: 'Australian Dollar',
  );

  /// Canadian dollar.
  static const cad = Currency(
    code: 'CAD',
    symbol: r'CA$',
    name: 'Canadian Dollar',
  );

  /// Japanese yen. Has no minor unit, so amounts are rounded to whole yen.
  static const jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    decimalDigits: 0,
    name: 'Japanese Yen',
  );

  /// All built-in currencies, useful for pickers.
  static const List<Currency> values = [usd, eur, gbp, inr, npr, aud, cad, jpy];

  /// ISO 4217 code, for example `USD`.
  final String code;

  /// Display symbol, for example `$` or `Rs.`.
  final String symbol;

  /// Number of digits after the decimal point (2 for USD, 0 for JPY).
  ///
  /// The calculation engine rounds every amount to this precision.
  final int decimalDigits;

  /// Whether the symbol is written before the amount (`$10`) or after (`10 kr`).
  final bool symbolBeforeAmount;

  /// Whether a space separates symbol and amount (`Rs. 10` vs `$10`).
  final bool spaceBetweenSymbolAndAmount;

  /// Optional human-readable name, for example `US Dollar`.
  final String? name;

  /// Returns a copy with the given fields replaced.
  Currency copyWith({
    String? code,
    String? symbol,
    int? decimalDigits,
    bool? symbolBeforeAmount,
    bool? spaceBetweenSymbolAndAmount,
    String? name,
  }) {
    return Currency(
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      decimalDigits: decimalDigits ?? this.decimalDigits,
      symbolBeforeAmount: symbolBeforeAmount ?? this.symbolBeforeAmount,
      spaceBetweenSymbolAndAmount:
          spaceBetweenSymbolAndAmount ?? this.spaceBetweenSymbolAndAmount,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Currency &&
      other.code == code &&
      other.symbol == symbol &&
      other.decimalDigits == decimalDigits &&
      other.symbolBeforeAmount == symbolBeforeAmount &&
      other.spaceBetweenSymbolAndAmount == spaceBetweenSymbolAndAmount &&
      other.name == name;

  @override
  int get hashCode => Object.hash(
        code,
        symbol,
        decimalDigits,
        symbolBeforeAmount,
        spaceBetweenSymbolAndAmount,
        name,
      );

  @override
  String toString() =>
      'Currency($code, $symbol, decimalDigits: $decimalDigits)';
}
