# flutter_invoice_generator

Create professional invoice PDFs in Flutter with a few lines of code.

> **Status: in development (Phase 5 of 10).** Models, validation, exact
> calculations, PDF generation with three templates (Classic, Modern,
> Minimal), theming and optional QR codes are ready. Preview and
> save/share/print are coming next. Not yet on pub.dev.

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

```dart
final totals = InvoiceCalculator.calculate(invoice);
print(totals.total); // 711.9  (700 - 10% = 630, + 13% VAT = 711.90)
```

```dart
final pdf = await InvoiceGenerator.generate(invoice);
pdf.bytes;     // Uint8List - upload, email or save it
pdf.pageCount; // long invoices continue on new pages automatically
```

```dart
final pdf = await InvoiceGenerator.generate(
  invoice,
  template: InvoiceTemplate.modern, // classic | modern | minimal
  theme: InvoiceTheme(primaryColor: PdfColor.fromHex('#16A34A')),
);
```

Money math uses exact decimals (no floating-point drift) and rounds half
away from zero to the currency's decimal places.

A learning guide that explains every design decision is in
[docs/learning/flutter_invoice_generator_guide.pdf](docs/learning/flutter_invoice_generator_guide.pdf).
