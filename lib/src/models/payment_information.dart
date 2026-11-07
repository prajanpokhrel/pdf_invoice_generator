import 'package:meta/meta.dart';

/// How the customer can pay. Every field is optional; only the fields you
/// set are printed.
///
/// Not every country uses IBAN or SWIFT, so use whichever fields apply and
/// put anything else in [instructions].
@immutable
final class PaymentInformation {
  /// Creates payment information.
  const PaymentInformation({
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.iban,
    this.swiftBic,
    this.routingNumber,
    this.paymentUrl,
    this.instructions,
  });

  /// Bank name.
  final String? bankName;

  /// Name on the account.
  final String? accountName;

  /// Account number.
  final String? accountNumber;

  /// International Bank Account Number.
  final String? iban;

  /// SWIFT / BIC code.
  final String? swiftBic;

  /// Routing, sort or IFSC code, depending on the country.
  final String? routingNumber;

  /// Link where the invoice can be paid online.
  final String? paymentUrl;

  /// Free-text instructions, for example `Pay within 30 days`.
  final String? instructions;

  /// Whether no field is set (nothing would be printed).
  bool get isEmpty =>
      bankName == null &&
      accountName == null &&
      accountNumber == null &&
      iban == null &&
      swiftBic == null &&
      routingNumber == null &&
      paymentUrl == null &&
      instructions == null;

  /// Returns a copy with the given fields replaced.
  PaymentInformation copyWith({
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? iban,
    String? swiftBic,
    String? routingNumber,
    String? paymentUrl,
    String? instructions,
  }) {
    return PaymentInformation(
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      swiftBic: swiftBic ?? this.swiftBic,
      routingNumber: routingNumber ?? this.routingNumber,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentInformation &&
      other.bankName == bankName &&
      other.accountName == accountName &&
      other.accountNumber == accountNumber &&
      other.iban == iban &&
      other.swiftBic == swiftBic &&
      other.routingNumber == routingNumber &&
      other.paymentUrl == paymentUrl &&
      other.instructions == instructions;

  @override
  int get hashCode => Object.hash(
        bankName,
        accountName,
        accountNumber,
        iban,
        swiftBic,
        routingNumber,
        paymentUrl,
        instructions,
      );

  @override
  String toString() => 'PaymentInformation(bank: $bankName)';
}
