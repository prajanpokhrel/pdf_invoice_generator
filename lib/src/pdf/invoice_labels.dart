import 'package:meta/meta.dart';

/// Every fixed word printed on the invoice. Override any of them to
/// translate or rename.
///
/// ```dart
/// const labels = InvoiceLabels(
///   invoiceTitle: 'TAX INVOICE',
///   billTo: 'Customer',
///   thankYou: null, // hide the thank-you line
/// );
/// ```
@immutable
final class InvoiceLabels {
  /// Creates labels. Defaults are English.
  const InvoiceLabels({
    this.invoiceTitle = 'INVOICE',
    this.invoiceNumber = 'Invoice No.',
    this.issueDate = 'Issue date',
    this.dueDate = 'Due date',
    this.billTo = 'Bill to',
    this.item = 'Item',
    this.quantity = 'Qty',
    this.unitPrice = 'Unit price',
    this.discount = 'Discount',
    this.tax = 'Tax',
    this.amount = 'Amount',
    this.taxExempt = 'Exempt',
    this.subtotal = 'Subtotal',
    this.total = 'Total',
    this.notes = 'Notes',
    this.terms = 'Terms',
    this.paymentInformation = 'Payment details',
    this.bankName = 'Bank',
    this.accountName = 'Account name',
    this.accountNumber = 'Account no.',
    this.iban = 'IBAN',
    this.swiftBic = 'SWIFT/BIC',
    this.routingNumber = 'Routing / sort code',
    this.paymentUrl = 'Pay online',
    this.taxId = 'Tax ID',
    this.registrationNumber = 'Reg. no.',
    this.sku = 'SKU',
    this.thankYou = 'Thank you for your business!',
    this.pageOf = 'Page {page} of {pages}',
    this.continued = 'continued',
    this.scanToPay = 'Scan to pay',
    this.scanToView = 'Scan to view online',
    this.amountDue = 'Amount due',
  });

  /// Big title, `INVOICE`.
  final String invoiceTitle;

  /// `Invoice No.`
  final String invoiceNumber;

  /// `Issue date`
  final String issueDate;

  /// `Due date`
  final String dueDate;

  /// Heading above the customer, `Bill to`.
  final String billTo;

  /// Items table column, `Item`.
  final String item;

  /// Items table column, `Qty`.
  final String quantity;

  /// Items table column, `Unit price`.
  final String unitPrice;

  /// Items table column and summary row, `Discount`.
  final String discount;

  /// Items table column, `Tax`.
  final String tax;

  /// Items table column, `Amount`.
  final String amount;

  /// Shown in the tax column for tax-exempt items, `Exempt`.
  final String taxExempt;

  /// Summary row, `Subtotal`.
  final String subtotal;

  /// Summary row, `Total`.
  final String total;

  /// Heading for `Invoice.notes`.
  final String notes;

  /// Heading for `Invoice.terms`.
  final String terms;

  /// Heading for payment information.
  final String paymentInformation;

  /// Payment field label.
  final String bankName;

  /// Payment field label.
  final String accountName;

  /// Payment field label.
  final String accountNumber;

  /// Payment field label.
  final String iban;

  /// Payment field label.
  final String swiftBic;

  /// Payment field label.
  final String routingNumber;

  /// Payment field label.
  final String paymentUrl;

  /// Prefix for tax IDs, `Tax ID`.
  final String taxId;

  /// Prefix for registration numbers, `Reg. no.`.
  final String registrationNumber;

  /// Prefix for item SKUs, `SKU`.
  final String sku;

  /// Closing line. `null` hides it.
  final String? thankYou;

  /// Page number text. `{page}` and `{pages}` are replaced.
  final String pageOf;

  /// Shown in the header of pages 2 and later.
  final String continued;

  /// Default caption of `InvoiceQrCode.payment`.
  final String scanToPay;

  /// Default caption of `InvoiceQrCode.invoiceUrl`.
  final String scanToView;

  /// Heading of the large total shown at the top of the Modern template.
  final String amountDue;

  /// [pageOf] with the numbers filled in.
  String formatPageOf(int page, int pages) =>
      pageOf.replaceAll('{page}', '$page').replaceAll('{pages}', '$pages');

  @override
  bool operator ==(Object other) =>
      other is InvoiceLabels &&
      other.invoiceTitle == invoiceTitle &&
      other.invoiceNumber == invoiceNumber &&
      other.issueDate == issueDate &&
      other.dueDate == dueDate &&
      other.billTo == billTo &&
      other.item == item &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice &&
      other.discount == discount &&
      other.tax == tax &&
      other.amount == amount &&
      other.taxExempt == taxExempt &&
      other.subtotal == subtotal &&
      other.total == total &&
      other.notes == notes &&
      other.terms == terms &&
      other.paymentInformation == paymentInformation &&
      other.bankName == bankName &&
      other.accountName == accountName &&
      other.accountNumber == accountNumber &&
      other.iban == iban &&
      other.swiftBic == swiftBic &&
      other.routingNumber == routingNumber &&
      other.paymentUrl == paymentUrl &&
      other.taxId == taxId &&
      other.registrationNumber == registrationNumber &&
      other.sku == sku &&
      other.thankYou == thankYou &&
      other.pageOf == pageOf &&
      other.continued == continued &&
      other.scanToPay == scanToPay &&
      other.scanToView == scanToView &&
      other.amountDue == amountDue;

  @override
  int get hashCode => Object.hashAll([
        invoiceTitle,
        invoiceNumber,
        issueDate,
        dueDate,
        billTo,
        item,
        quantity,
        unitPrice,
        discount,
        tax,
        amount,
        taxExempt,
        subtotal,
        total,
        notes,
        terms,
        paymentInformation,
        bankName,
        accountName,
        accountNumber,
        iban,
        swiftBic,
        routingNumber,
        paymentUrl,
        taxId,
        registrationNumber,
        sku,
        thankYou,
        pageOf,
        continued,
        scanToPay,
        scanToView,
        amountDue,
      ]);
}
