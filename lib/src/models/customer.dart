import 'package:meta/meta.dart';

/// The customer being billed ("Bill To").
///
/// Only [name] is required. Every other field is printed only when provided.
@immutable
final class Customer {
  /// Creates a customer.
  const Customer({
    required this.name,
    this.companyName,
    this.email,
    this.phone,
    this.address,
    this.taxId,
  });

  /// Person or organisation name.
  final String name;

  /// Company the person belongs to, printed under [name].
  final String? companyName;

  /// Contact email.
  final String? email;

  /// Contact phone number, printed as given.
  final String? phone;

  /// Billing address. Use `\n` for multiple lines.
  final String? address;

  /// Customer tax identifier such as a VAT, PAN or GST number.
  final String? taxId;

  /// Returns a copy with the given fields replaced.
  Customer copyWith({
    String? name,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? taxId,
  }) {
    return Customer(
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Customer &&
      other.name == name &&
      other.companyName == companyName &&
      other.email == email &&
      other.phone == phone &&
      other.address == address &&
      other.taxId == taxId;

  @override
  int get hashCode =>
      Object.hash(name, companyName, email, phone, address, taxId);

  @override
  String toString() => 'Customer($name)';
}
