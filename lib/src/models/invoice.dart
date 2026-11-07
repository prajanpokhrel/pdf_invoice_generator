import 'package:meta/meta.dart';

import '../utils/equality.dart';
import '../utils/tax_merge.dart';
import 'business.dart';
import 'currency.dart';
import 'customer.dart';
import 'discount.dart';
import 'invoice_detail.dart';
import 'invoice_item.dart';
import 'invoice_qr_code.dart';
import 'payment_information.dart';
import 'tax.dart';

/// All the data printed on an invoice.
///
/// An [Invoice] holds *data only*. How it looks (template, colours, fonts,
/// page size) is chosen when generating the PDF, so the same invoice can be
/// rendered in any style.
///
/// ```dart
/// final invoice = Invoice(
///   invoiceNumber: 'INV-1001',
///   issueDate: DateTime(2026, 11, 7),
///   seller: const Business(name: 'ABC Technologies'),
///   customer: const Customer(name: 'John Doe'),
///   items: [InvoiceItem(name: 'Design', quantity: 2, unitPrice: 100)],
///   tax: const Tax(name: 'VAT', percentage: 13),
///   currency: Currency.npr,
/// );
/// ```
///
/// The seller's logo is set on [Business.logo].
@immutable
final class Invoice {
  /// Creates an invoice.
  ///
  /// Pass either [tax] (one tax) or [taxes] (several), not both. Passing both
  /// throws an [ArgumentError]. Lists and maps are copied, so later changes
  /// to the originals do not affect this invoice.
  Invoice({
    required this.invoiceNumber,
    required this.issueDate,
    required this.seller,
    required this.customer,
    required List<InvoiceItem> items,
    this.dueDate,
    this.currency = Currency.usd,
    Tax? tax,
    List<Tax>? taxes,
    this.discount,
    this.notes,
    this.terms,
    this.paymentInformation,
    this.qrCode,
    List<InvoiceDetail> details = const [],
    Map<String, String> metadata = const {},
  })  : items = List.unmodifiable(items),
        taxes = mergeTaxes(tax, taxes) ?? const [],
        details = List.unmodifiable(details),
        metadata = Map.unmodifiable(metadata);

  /// Invoice number, for example `INV-1001`. Must not be empty.
  final String invoiceNumber;

  /// Date the invoice is issued.
  final DateTime issueDate;

  /// Date payment is due. Optional (for example "due on receipt").
  final DateTime? dueDate;

  /// Who is selling.
  final Business seller;

  /// Who is being billed.
  final Customer customer;

  /// The lines of the invoice. Read-only.
  final List<InvoiceItem> items;

  /// Currency used to round and display amounts. Defaults to [Currency.usd].
  final Currency currency;

  /// Taxes applied to items that do not define their own. Empty means no
  /// tax. Read-only.
  final List<Tax> taxes;

  /// Discount on the whole invoice, applied to the subtotal before tax.
  final Discount? discount;

  /// Notes printed near the bottom, for example a thank-you message.
  final String? notes;

  /// Terms and conditions.
  final String? terms;

  /// How the customer can pay.
  final PaymentInformation? paymentInformation;

  /// Optional QR code (payment link, invoice link or custom text), printed
  /// next to the payment details.
  final InvoiceQrCode? qrCode;

  /// Extra label/value rows printed in the header, such as `PO Number`.
  final List<InvoiceDetail> details;

  /// Your own key/value data. Never printed; useful for IDs or tracking.
  final Map<String, String> metadata;

  /// Returns a copy with the given fields replaced.
  ///
  /// Passing `null` keeps the current value.
  Invoice copyWith({
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    Business? seller,
    Customer? customer,
    List<InvoiceItem>? items,
    Currency? currency,
    List<Tax>? taxes,
    Discount? discount,
    String? notes,
    String? terms,
    PaymentInformation? paymentInformation,
    InvoiceQrCode? qrCode,
    List<InvoiceDetail>? details,
    Map<String, String>? metadata,
  }) {
    return Invoice(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      seller: seller ?? this.seller,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      currency: currency ?? this.currency,
      taxes: taxes ?? this.taxes,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      paymentInformation: paymentInformation ?? this.paymentInformation,
      qrCode: qrCode ?? this.qrCode,
      details: details ?? this.details,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Invoice &&
      other.invoiceNumber == invoiceNumber &&
      other.issueDate == issueDate &&
      other.dueDate == dueDate &&
      other.seller == seller &&
      other.customer == customer &&
      listEquals(other.items, items) &&
      other.currency == currency &&
      listEquals(other.taxes, taxes) &&
      other.discount == discount &&
      other.notes == notes &&
      other.terms == terms &&
      other.paymentInformation == paymentInformation &&
      other.qrCode == qrCode &&
      listEquals(other.details, details) &&
      mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        invoiceNumber,
        issueDate,
        dueDate,
        seller,
        customer,
        Object.hashAll(items),
        currency,
        Object.hashAll(taxes),
        discount,
        notes,
        terms,
        paymentInformation,
        qrCode,
        Object.hashAll(details),
        mapHash(metadata),
      );

  @override
  String toString() =>
      'Invoice($invoiceNumber, ${items.length} items, ${currency.code})';
}
