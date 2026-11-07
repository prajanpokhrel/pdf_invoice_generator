import 'package:meta/meta.dart';

/// What an [InvoiceQrCode] points to. Used to choose the default caption.
enum InvoiceQrCodeType {
  /// A link where the invoice can be paid.
  payment,

  /// A link where the invoice can be viewed online.
  invoiceUrl,

  /// Any other text (for example a bank-specific payment payload).
  custom,
}

/// An optional QR code printed next to the payment details.
///
/// ```dart
/// InvoiceQrCode.payment('https://pay.example.com/INV-1001')
/// InvoiceQrCode.invoiceUrl('https://example.com/invoices/1001')
/// InvoiceQrCode(data: 'any text', caption: 'Scan me')
/// ```
///
/// The caption defaults to `InvoiceLabels.scanToPay` / `scanToView`; set
/// [caption] to override it, or pass an empty string to hide it.
@immutable
final class InvoiceQrCode {
  /// A QR code with custom [data].
  const InvoiceQrCode({
    required this.data,
    this.caption,
    this.type = InvoiceQrCodeType.custom,
  });

  /// A QR code linking to a payment page.
  const InvoiceQrCode.payment(this.data, {this.caption})
      : type = InvoiceQrCodeType.payment;

  /// A QR code linking to the online invoice.
  const InvoiceQrCode.invoiceUrl(this.data, {this.caption})
      : type = InvoiceQrCodeType.invoiceUrl;

  /// The encoded text or URL. Must not be empty.
  final String data;

  /// Text under the code. `null` uses the label for [type].
  final String? caption;

  /// What the code points to.
  final InvoiceQrCodeType type;

  @override
  bool operator ==(Object other) =>
      other is InvoiceQrCode &&
      other.data == data &&
      other.caption == caption &&
      other.type == type;

  @override
  int get hashCode => Object.hash(data, caption, type);

  @override
  String toString() => 'InvoiceQrCode(${type.name}, $data)';
}
