# flutter_invoice_generator

Create professional invoice PDFs in Flutter with a few lines of code.

> **Status: in development (Phase 7 of 10).** Models, validation, exact
> calculations, PDF generation with three templates, theming, QR codes,
> the `InvoicePreview` widget and save/share/print are ready. The example
> app and full documentation are coming next. Not yet on pub.dev.

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

```dart
// In your widget tree - shows the real PDF, updates when the invoice changes.
InvoicePreview(invoice: invoice, template: InvoiceTemplate.modern)
```

Money math uses exact decimals (no floating-point drift) and rounds half
away from zero to the currency's decimal places.

## Save, share and print

```dart
await InvoiceGenerator.print(invoice);              // system print dialog
await InvoiceGenerator.share(invoice);              // share sheet
final saved = await InvoiceGenerator.save(invoice); // file (download on web)
print(saved.path);

// Already have a PDF (e.g. from InvoicePreview.onGenerated)? Reuse it:
await pdf.share();
```

All three generate the PDF first, so invalid data throws
`InvoiceValidationException` before any dialog opens. Platform failures throw
`InvoiceOutputException`.

### Platform support

| Platform | `generate` / `InvoicePreview` | `print` | `share` | `save` (default location) |
|---|---|---|---|---|
| Android | ✅ | System print dialog | Share sheet (`Intent.createChooser`) | App documents dir (private to the app) |
| iOS | ✅ | System print dialog | Share sheet (`UIActivityViewController`) | App `Documents` (visible in Files only with `UIFileSharingEnabled`) |
| macOS | ✅ | Print dialog — needs the `com.apple.security.print` entitlement | Share menu (`NSSharingServicePicker`) | `~/Library/Containers/<app>/Data/Documents` (sandboxed) |
| Windows | ✅ | Print dialog | ⚠️ No share sheet: opens the PDF in the default viewer | `Documents` |
| Linux | ✅ | Print dialog | ⚠️ No share sheet: opens the PDF with `xdg-open` | `~/Documents` (XDG) |
| Web | ✅ | Browser print | Browser download | Browser download (`saved.path == null`) |

How this table was checked:

* **Automated tests** (all platforms' Dart code): print/share/save call the
  plugins with the right PDF, file name, page format and email fields; save
  writes the exact bytes; errors are reported; on the **web** (tested in a
  Chromium browser), `save` downloads instead of writing a file.
* **Native behaviour** (dialogs, share sheets, folders) comes from reading the
  `printing` and `path_provider` source code. It is verified by hand on macOS
  in the example app; the other platforms are not yet verified on a device.

Tip: to let users choose where a file goes on Android/iOS, use `share` — the
share sheet includes "Save to Files" / "Save to Drive".

A learning guide that explains every design decision is in
[docs/learning/flutter_invoice_generator_guide.pdf](docs/learning/flutter_invoice_generator_guide.pdf).
