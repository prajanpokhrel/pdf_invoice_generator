# flutter_invoice_generator

Create professional invoice PDFs in Flutter with a few lines of code.

> **Status: in development (Phase 2 of 10).** The data models are ready.
> The calculation engine, PDF generation, templates, preview and
> save/share/print are coming in the next phases. Not yet on pub.dev.

```dart
final invoice = Invoice(
  invoiceNumber: 'INV-1001',
  issueDate: DateTime.now(),
  seller: const Business(name: 'ABC Technologies'),
  customer: const Customer(name: 'John Doe'),
  items: [
    InvoiceItem(name: 'Flutter App Development', quantity: 1, unitPrice: 500),
    InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100),
  ],
  tax: const Tax(name: 'VAT', percentage: 13),
  discount: const Discount.percentage(10),
  currency: Currency.usd,
);
```

A learning guide that explains every design decision is in
[docs/learning/flutter_invoice_generator_guide.pdf](docs/learning/flutter_invoice_generator_guide.pdf).
