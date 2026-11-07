import 'package:meta/meta.dart';

import 'invoice_logo.dart';

/// The seller issuing the invoice.
///
/// Only [name] is required. Every other field is printed only when provided.
///
/// ```dart
/// const seller = Business(
///   name: 'ABC Technologies',
///   email: 'hello@abc.com',
///   address: 'Kathmandu, Nepal',
/// );
/// ```
@immutable
final class Business {
  /// Creates a business.
  const Business({
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.taxId,
    this.registrationNumber,
    this.logo,
  });

  /// Legal or trading name.
  final String name;

  /// Contact email.
  final String? email;

  /// Contact phone number, printed as given.
  final String? phone;

  /// Postal address. Use `\n` for multiple lines.
  final String? address;

  /// Website, for example `abc.com`.
  final String? website;

  /// Tax identifier such as a VAT, PAN or GST number.
  final String? taxId;

  /// Company registration number.
  final String? registrationNumber;

  /// Logo printed in the invoice header.
  final InvoiceLogo? logo;

  /// Returns a copy with the given fields replaced.
  Business copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? taxId,
    String? registrationNumber,
    InvoiceLogo? logo,
  }) {
    return Business(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      logo: logo ?? this.logo,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Business &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.address == address &&
      other.website == website &&
      other.taxId == taxId &&
      other.registrationNumber == registrationNumber &&
      other.logo == logo;

  @override
  int get hashCode => Object.hash(
        name,
        email,
        phone,
        address,
        website,
        taxId,
        registrationNumber,
        logo,
      );

  @override
  String toString() => 'Business($name)';
}
