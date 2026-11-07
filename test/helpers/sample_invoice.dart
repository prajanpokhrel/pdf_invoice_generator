import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';

/// The invoice from the README quick start, reused across tests.
Invoice sampleInvoice({
  List<InvoiceItem>? items,
  Currency currency = Currency.usd,
}) {
  return Invoice(
    invoiceNumber: 'INV-1001',
    issueDate: DateTime(2026, 11, 7),
    dueDate: DateTime(2026, 12, 7),
    seller: const Business(
      name: 'ABC Technologies',
      email: 'hello@abc.com',
      phone: '+977 9800000000',
      address: 'Kathmandu, Nepal',
    ),
    customer: const Customer(
      name: 'John Doe',
      email: 'john@example.com',
      phone: '+977 9811111111',
      address: 'Lalitpur, Nepal',
    ),
    items: items ??
        [
          InvoiceItem(
            name: 'Flutter App Development',
            quantity: 1,
            unitPrice: 500,
          ),
          InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100),
        ],
    tax: const Tax(name: 'VAT', percentage: 13),
    discount: const Discount(type: DiscountType.percentage, value: 10),
    currency: currency,
  );
}
