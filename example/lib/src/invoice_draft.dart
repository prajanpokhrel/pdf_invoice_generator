import 'package:flutter/foundation.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';

/// What kind of invoice-level discount the user picked.
enum DiscountMode { none, percentage, fixed }

/// One editable line in the form.
class DraftItem {
  DraftItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.description = '',
    this.unit = '',
  }) : id = _nextId++;

  static int _nextId = 0;

  /// Stable id so list rows keep their text fields when items are removed.
  final int id;
  String name;
  String description;
  double quantity;
  double unitPrice;
  String unit;
}

/// The mutable state behind the editor form.
///
/// The package's models are immutable; a form needs something it can change
/// field by field. [toInvoice] converts this draft into a real [Invoice].
class InvoiceDraft extends ChangeNotifier {
  // Business
  String businessName = 'ABC Technologies';
  String businessEmail = 'hello@abc.com';
  String businessPhone = '+977 9800000000';
  String businessAddress = 'Durbarmarg, Kathmandu, Nepal';
  String businessTaxId = 'PAN 601234567';
  bool showLogo = true;

  // Customer
  String customerName = 'John Doe';
  String customerCompany = 'Doe Retail Pvt. Ltd.';
  String customerEmail = 'john@example.com';
  String customerAddress = 'Pulchowk, Lalitpur, Nepal';

  // Invoice
  String invoiceNumber = 'INV-1001';
  DateTime issueDate = DateTime(2026, 11, 7);
  int dueInDays = 30;
  final List<DraftItem> items = [
    DraftItem(
      name: 'Flutter App Development',
      description: 'iOS + Android app, 3 sprints',
      quantity: 1,
      unitPrice: 500,
    ),
    DraftItem(
      name: 'UI/UX Design',
      quantity: 2,
      unitPrice: 100,
      unit: 'screens',
    ),
    DraftItem(name: 'Consulting', quantity: 2.5, unitPrice: 80, unit: 'hrs'),
  ];

  // Pricing
  Currency currency = Currency.usd;
  String taxName = 'VAT';
  double taxPercentage = 13;
  DiscountMode discountMode = DiscountMode.percentage;
  double discountValue = 10;

  // Extras
  String notes = 'Thank you for choosing ABC Technologies.';
  String bankName = 'Nabil Bank';
  String accountNumber = '0101 0172 0012';
  bool includeQrCode = true;

  // Appearance
  InvoiceTemplate template = InvoiceTemplate.modern;
  PdfColor primaryColor = PdfColor.fromHex('#2563EB');
  PdfPageFormat pageFormat = PdfPageFormat.a4;

  /// Runs [change] and tells listeners (the preview) to update.
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void addItem() => update(
    () => items.add(DraftItem(name: 'New item', quantity: 1, unitPrice: 0)),
  );

  void removeItem(DraftItem item) => update(() => items.remove(item));

  InvoiceTheme get theme =>
      InvoiceTheme(primaryColor: primaryColor, pageFormat: pageFormat);

  String? _blankToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  /// Converts the form into the package's immutable [Invoice].
  Invoice toInvoice() {
    return Invoice(
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
      dueDate: issueDate.add(Duration(days: dueInDays)),
      seller: Business(
        name: businessName,
        email: _blankToNull(businessEmail),
        phone: _blankToNull(businessPhone),
        address: _blankToNull(businessAddress),
        taxId: _blankToNull(businessTaxId),
        logo: showLogo ? const InvoiceLogo.asset('assets/logo.png') : null,
      ),
      customer: Customer(
        name: customerName,
        companyName: _blankToNull(customerCompany),
        email: _blankToNull(customerEmail),
        address: _blankToNull(customerAddress),
      ),
      items: [
        for (final item in items)
          InvoiceItem(
            name: item.name,
            description: _blankToNull(item.description),
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            unit: _blankToNull(item.unit),
          ),
      ],
      currency: currency,
      taxes: [
        if (taxPercentage > 0)
          Tax(
            name: taxName.trim().isEmpty ? 'Tax' : taxName,
            percentage: taxPercentage,
          ),
      ],
      discount: switch (discountMode) {
        DiscountMode.none => null,
        DiscountMode.percentage => Discount.percentage(discountValue),
        DiscountMode.fixed => Discount.fixed(discountValue),
      },
      notes: _blankToNull(notes),
      paymentInformation: PaymentInformation(
        bankName: _blankToNull(bankName),
        accountName: _blankToNull(businessName),
        accountNumber: _blankToNull(accountNumber),
      ),
      qrCode: includeQrCode
          ? InvoiceQrCode.payment('https://pay.example.com/$invoiceNumber')
          : null,
    );
  }
}
