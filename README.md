# flutter_invoice_generator

Create professional invoice PDFs in Flutter with a few lines of code.
Exact money math, taxes, discounts, multi-page tables, three templates,
a live preview widget, and save / share / print.

```dart
final pdf = await InvoiceGenerator.generate(invoice);
```

- ✅ **Correct totals:** exact decimal math, no `0.1 + 0.2` surprises
- ✅ **Multi-page:** long item lists continue with repeated table headers
- ✅ **3 templates:** Classic, Modern, Minimal, all themeable
- ✅ **Offline:** bundled font with `$ € £ ₹ ¥`; no network needed
- ✅ **Preview, save, share, print:** Android, iOS, macOS, Windows, Linux, Web
- ✅ **No backend, no Firebase, no global state**

| Classic | Modern | Minimal |
|---|---|---|
| ![Classic](https://raw.githubusercontent.com/OWNER/REPO/main/docs/learning/images/template_classic.png) | ![Modern](https://raw.githubusercontent.com/OWNER/REPO/main/docs/learning/images/template_modern.png) | ![Minimal](https://raw.githubusercontent.com/OWNER/REPO/main/docs/learning/images/template_minimal.png) |

---

## Contents

1. [Installation](#installation)
2. [Quick start](#quick-start)
3. [Complete example](#complete-example)
4. [Templates](#templates)
5. [Customization](#customization)
6. [Tax](#tax)
7. [Discounts](#discounts)
8. [Currency](#currency)
9. [Calculations and rounding](#calculations-and-rounding)
10. [PDF generation](#pdf-generation)
11. [Multiple pages](#multiple-pages)
12. [Invoice preview widget](#invoice-preview-widget)
13. [Save, share and print](#save-share-and-print)
14. [Platform support](#platform-support)
15. [Errors](#errors)
16. [FAQ](#faq)
17. [Troubleshooting](#troubleshooting)
18. [Roadmap](#roadmap)

---

## Installation

```bash
flutter pub add flutter_invoice_generator
```

```dart
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
```

That single import gives you everything, including `PdfColor`,
`PdfPageFormat` and `Font`, so you never need to import `package:pdf`.

**macOS only:** to print, add this to
`macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.print</key>
<true/>
```

Requires Flutter 3.27+ / Dart 3.6+.

---

## Quick start

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
);

final pdf = await InvoiceGenerator.generate(invoice); // pdf.bytes is the file
await InvoiceGenerator.share(invoice);                 // or print / save
```

---

## Complete example

```dart
final invoice = Invoice(
  invoiceNumber: 'INV-1001',
  issueDate: DateTime(2026, 11, 7),
  dueDate: DateTime(2026, 12, 7),
  seller: const Business(
    name: 'ABC Technologies',
    email: 'hello@abc.com',
    phone: '+977 9800000000',
    address: 'Durbarmarg\nKathmandu, Nepal',
    website: 'abc.com',
    taxId: 'PAN 601234567',
    logo: InvoiceLogo.asset('assets/logo.png'),
  ),
  customer: const Customer(
    name: 'John Doe',
    companyName: 'Doe Retail Pvt. Ltd.',
    email: 'john@example.com',
    address: 'Lalitpur, Nepal',
  ),
  items: [
    InvoiceItem(
      name: 'Flutter App Development',
      description: 'iOS + Android app, 3 sprints',
      quantity: 1,
      unitPrice: 500,
    ),
    InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100, unit: 'screens'),
    InvoiceItem(name: 'Consulting', quantity: 2.5, unitPrice: 80, unit: 'hrs'),
  ],
  tax: const Tax(name: 'VAT', percentage: 13),
  discount: const Discount(type: DiscountType.percentage, value: 10),
  currency: Currency.usd,
  notes: 'Thank you for choosing ABC Technologies.',
  terms: 'Payment due within 30 days.',
  paymentInformation: const PaymentInformation(
    bankName: 'Nabil Bank',
    accountName: 'ABC Technologies',
    accountNumber: '0101 0172 0012',
    swiftBic: 'NARBNPKA',
  ),
  qrCode: const InvoiceQrCode.payment('https://pay.example.com/INV-1001'),
  details: const [InvoiceDetail(label: 'PO Number', value: 'PO-7781')],
  metadata: const {'orderId': '42'}, // your data, never printed
);

final pdf = await InvoiceGenerator.generate(
  invoice,
  template: InvoiceTemplate.modern,
  theme: InvoiceTheme(primaryColor: PdfColor.fromHex('#16A34A')),
);
print(pdf.totals.total); // 915.3
```

A full app (editor + live preview + share/print/save) is in
[`example/`](example/).

Every field except `invoiceNumber`, `issueDate`, `seller`, `customer` and
`items` is optional. Models are immutable: use `copyWith` to change them.

---

## Templates

```dart
await InvoiceGenerator.generate(invoice, template: InvoiceTemplate.classic); // default
await InvoiceGenerator.generate(invoice, template: InvoiceTemplate.modern);
await InvoiceGenerator.generate(invoice, template: InvoiceTemplate.minimal);
```

| Template | Look |
|---|---|
| `classic` | Logo and seller left, large title right, grid table with a coloured header, filled total row |
| `modern` | Coloured header band, highlighted "Amount due" card, striped table, rounded summary card |
| `minimal` | No fills, thin lines, generous white space |

Templates only change the look: the data and the totals are identical for
every template. `InvoiceTemplate.values` lists them all (handy for pickers).

---

## Customization

Appearance is set with `InvoiceTheme`, separate from the invoice data, so the
same invoice can be rendered in any style. Every option has a default.

```dart
final theme = InvoiceTheme(
  pageFormat: PdfPageFormat.letter,       // default: A4
  margin: 40,                             // points (72 = 1 inch)
  primaryColor: PdfColor.fromHex('#2563EB'),
  secondaryColor: PdfColors.blueGrey600,  // addresses, labels
  textColor: PdfColors.black,
  baseFontSize: 10,                       // all text scales from this
  sectionSpacing: 14,                     // space between sections
  borderRadius: 8,                        // rounded corners (Modern)
  tableStyle: const InvoiceTableStyle(
    headerColor: PdfColors.blueGrey800,
    headerTextColor: PdfColors.white,
    stripeColor: PdfColors.grey100,
    showBorders: false,
    rowPadding: 6,
  ),
  showLogo: true,
  showPageNumbers: true,
  showContinuationHeader: true,           // "INVOICE INV-1001 (continued)"
  footerText: 'ABC Technologies · abc.com', // default: seller name
  locale: 'en_US',                        // number separators, month names
  dateFormat: 'dd/MM/yyyy',               // default: 'MMM d, yyyy'
);
```

`InvoiceTableStyle` fields left `null` keep the template's own table look.

### Labels and translation

Every fixed word on the PDF comes from `InvoiceLabels`:

```dart
const labels = InvoiceLabels(
  invoiceTitle: 'FACTURE',
  billTo: 'Facturer à',
  total: 'Total TTC',
  pageOf: 'Page {page} sur {pages}',
  thankYou: null, // hide the thank-you line
);
await InvoiceGenerator.generate(invoice, labels: labels);
```

### Fonts

The bundled **Noto Sans** covers Latin, Greek and Cyrillic, plus currency
symbols such as `$ € £ ₹ ¥ ₨`. For other scripts (Devanagari, Arabic, CJK…),
add a font:

```dart
final devanagari = Font.ttf(
  await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'),
);
final theme = InvoiceTheme(fontFallback: [devanagari]);
// or replace the font entirely: InvoiceTheme(font: myFont, boldFont: myBold)
```

### Logo

```dart
Business(name: 'ABC', logo: InvoiceLogo.asset('assets/logo.png'))   // app asset
Business(name: 'ABC', logo: InvoiceLogo.memory(bytes))              // Uint8List
Business(name: 'ABC', logo: InvoiceLogo.network('https://…/logo.png')) // downloads
```

PNG, JPEG, GIF, BMP, WebP and TIFF are supported. Images larger than
1024 px are scaled down automatically. Prefer `asset` / `memory`: they work
offline. A broken or missing logo throws `InvoiceImageException`.

### QR code

```dart
qrCode: InvoiceQrCode.payment('https://pay.example.com/INV-1001') // "Scan to pay"
qrCode: InvoiceQrCode.invoiceUrl('https://example.com/i/1001')    // "Scan to view online"
qrCode: InvoiceQrCode(data: 'any text', caption: 'Our website')
```

---

## Tax

```dart
tax: const Tax(name: 'VAT', percentage: 13)          // one tax
taxes: const [                                        // several taxes
  Tax(name: 'CGST', percentage: 9),
  Tax(name: 'SGST', percentage: 9),
]
```

- No country rules are built in: you provide the name and rate.
- Each tax is applied to the amount **after** discounts. Taxes are never
  charged on other taxes.
- Items can override the invoice taxes:

```dart
InvoiceItem(name: 'Book', quantity: 1, unitPrice: 20,
    tax: const Tax(name: 'GST', percentage: 5)) // this item: GST 5%
InvoiceItem(name: 'Export', quantity: 1, unitPrice: 50,
    taxes: const [])                             // this item: tax-exempt
```

When items have their own taxes, a "Tax" column appears in the table, and
the summary shows one line per tax rate.

---

## Discounts

```dart
discount: const Discount.percentage(10)  // 10% off the subtotal
discount: const Discount.fixed(50)       // 50.00 off the subtotal
discount: const Discount(type: DiscountType.percentage, value: 10) // long form
discount: const Discount.fixed(5, label: 'Loyalty discount')       // custom label
```

Items can have their own discount too, which is applied to that line before
the invoice discount:

```dart
InvoiceItem(name: 'Design', quantity: 2, unitPrice: 100,
    discount: const Discount.percentage(10)) // line total 180.00
```

---

## Currency

```dart
currency: Currency.npr   // Rs. 1,234.50
```

Built in: `usd`, `eur`, `gbp`, `inr`, `npr`, `aud`, `cad`, `jpy` (no
decimals). `Currency.values` lists them.

Create your own:

```dart
const kwd = Currency(code: 'KWD', symbol: 'KD', decimalDigits: 3);
const sek = Currency(
  code: 'SEK',
  symbol: 'kr',
  symbolBeforeAmount: false,        // 10.00 kr
  spaceBetweenSymbolAndAmount: true,
);
```

A currency only controls formatting and rounding. There is no conversion.
Format amounts in your own UI the same way as the PDF:

```dart
InvoiceFormatter(currency: Currency.usd).money(1234.5); // $1,234.50
```

---

## Calculations and rounding

The totals are calculated separately from the PDF, so you can use them
anywhere:

```dart
final totals = InvoiceCalculator.calculate(invoice);
totals.subtotal;          // 700.0   sum of line totals
totals.discountAmount;    // 70.0
totals.taxableAmount;     // 630.0   subtotal - discount
totals.taxLines;          // [InvoiceTaxLine(VAT: 81.9)]
totals.taxAmount;         // 81.9
totals.total;             // 711.9
totals.totalInMinorUnits; // 71190   cents, e.g. for a payment gateway
totals.lines[0].lineTotal;
```

```text
line total     = quantity × unit price − item discount
subtotal       = Σ line totals
taxable amount = subtotal − invoice discount
tax            = taxable amount × rate   (per tax rate)
total          = taxable amount + Σ taxes
```

**Precision.** Every number is read as the exact decimal it prints as, and
all math uses integers, so `1.005` really is 1.005 and sums never drift.

**Rounding.** Amounts are rounded to the currency's decimals (2 for USD, 0
for JPY) using **round half away from zero** (0.125 → 0.13). Each line,
discount and tax is rounded once; subtotal, taxable amount and total are
exact sums, so the printed numbers always add up. Tax is rounded per rate on
the summed amount, not per line. When items have different tax rates, the
invoice discount is shared across lines in proportion to their value, and
the shares always add up exactly to the discount.

Quantities may be fractional (`2.5` hours, `0.75` kg). Zero quantities and
prices are allowed; negative ones are rejected.

---

## PDF generation

```dart
final pdf = await InvoiceGenerator.generate(
  invoice,
  template: InvoiceTemplate.classic,  // optional
  theme: const InvoiceTheme(),        // optional
  labels: const InvoiceLabels(),      // optional
);

pdf.bytes;      // Uint8List: upload, email, store
pdf.fileName;   // 'INV-1001.pdf' (unsafe characters replaced)
pdf.pageCount;  // 1
pdf.totals;     // the numbers printed on the PDF
```

Generation runs on the device and works offline (unless the logo is
`InvoiceLogo.network`). The invoice is validated first.

---

## Multiple pages

Nothing to configure. When the items don't fit on one page:

- the table continues on the next page, with its **header row repeated**;
- pages 2+ start with a small "INVOICE INV-1001 (continued)" line;
- every page shows "Page X of Y" in the footer;
- the thank-you line is never left alone on an empty page.

Tested with 1, 10, 50, 150 and 1000 items.

---

## Invoice preview widget

```dart
InvoicePreview(
  invoice: invoice,
  template: InvoiceTemplate.modern,   // optional, like generate()
  theme: theme,                       // optional
  allowPrinting: true,                // optional toolbar
  allowSharing: true,
  onGenerated: (pdf) => lastPdf = pdf, // reuse for your own buttons
  errorBuilder: (context, error) => Text(error.message),
)
```

- Shows the **real PDF**, so it always matches what you save or print.
- Regenerates only when `invoice`, `template`, `theme` or `labels` change
  (compared by value), and keeps the previous version on screen meanwhile.
- Invalid data shows the list of problems instead of crashing.
- Also available: `labels`, `maxPageWidth`, `backgroundColor`,
  `loadingBuilder`, `onError`.

---

## Save, share and print

```dart
await InvoiceGenerator.print(invoice);              // print dialog (false = cancelled)
await InvoiceGenerator.share(invoice,
    subject: 'Invoice INV-1001', text: 'Please find attached.');
final saved = await InvoiceGenerator.save(invoice); // InvoiceSaveResult
print(saved.path); // null on the web (downloaded instead)
```

Already have a PDF (for example from `InvoicePreview.onGenerated`)? Reuse it
so nothing is generated twice:

```dart
await pdf.print();
await pdf.share();
await pdf.save(directory: '/path/to/folder', fileName: 'invoice.pdf');
```

On iPad, pass `sharePositionOrigin` (the share button's `Rect`) so the
share popover points at the button.

---

## Platform support

| Platform | `generate` / `InvoicePreview` | `print` | `share` | `save` (default location) |
|---|---|---|---|---|
| Android | ✅ | System print dialog | Share sheet | App documents dir (private to the app) |
| iOS | ✅ | System print dialog | Share sheet | App `Documents` (visible in Files only with `UIFileSharingEnabled`) |
| macOS | ✅ | Print dialog (needs the print entitlement) | Share menu | `~/Library/Containers/<app>/Data/Documents` |
| Windows | ✅ | Print dialog | ⚠️ No share sheet: opens the PDF in the default viewer | `Documents` |
| Linux | ✅ | Print dialog | ⚠️ No share sheet: opens the PDF with `xdg-open` | `~/Documents` |
| Web | ✅ | Browser print | Browser download | Browser download (`path == null`) |

**How this was verified:**

- **Automated tests:** generation, preview logic and the Dart side of
  print/share/save, with faked plugins. Pure-Dart parts also run in a
  browser, and so does the web `save()` download.
- **On a real Mac:** an integration test confirmed that the preview renders
  real pages and that `save()` writes into the sandbox path above.
- **From the plugins' source code:** the native dialogs and share sheets.
  They have not yet been checked by hand on every platform.

To let users choose where a file goes on Android or iOS, use `share`: the
share sheet includes "Save to Files" / "Save to Drive".

---

## Errors

Every error is an `InvoiceException` with a readable `message`:

| Exception | When |
|---|---|
| `InvoiceValidationException` | Invalid data. `issues` lists **every** problem, e.g. `items[2].quantity: must not be negative` |
| `InvoiceImageException` | Logo missing, corrupt, unsupported or failed to download |
| `InvoiceGenerationException` | Anything else while building the PDF (e.g. unknown locale) |
| `InvoiceOutputException` | Print/share/save failed on the platform |

```dart
try {
  await InvoiceGenerator.share(invoice);
} on InvoiceValidationException catch (e) {
  for (final issue in e.issues) print('${issue.field}: ${issue.message}');
} on InvoiceException catch (e) {
  print(e.message);
}
```

Validate early (for example in a form) with
`InvoiceValidator.validate(invoice)`, which returns the list of issues.

---

## FAQ

**Does it need internet, Firebase or a server?**
No. Everything runs on the device. Only `InvoiceLogo.network` downloads.

**Can I use the totals without making a PDF?**
Yes: `InvoiceCalculator.calculate(invoice)`.

**Why are amounts `double` if the math is exact?**
The math uses exact integers internally; the results are rounded values
returned as `double` for convenience. Use `totalInMinorUnits` when you need
an integer.

**Are taxes for my country built in?**
No, on purpose. You pass the name and rate, so it works everywhere.

**Can I build my own template?**
Not yet; the three built-in templates are themeable. Custom templates are on
the roadmap.

**How do I put the template inside my saved invoice data?**
You don't need to: `Invoice` holds data only. Store your template choice
separately and pass it to `generate`.

**Can I generate on a server with plain Dart?**
Not with this package yet; it uses Flutter for assets and fonts.

---

## Troubleshooting

**`InvoiceOutputException: … plugin is not available`**
You added the package while the app was running. Stop the app and run it
again; a hot restart does not load new plugins.

**Printing does nothing on macOS**
Add the `com.apple.security.print` entitlement (see
[Installation](#installation)).

**`Locale "…" is not supported` / `initializeDateFormatting`**
Number formats work for every locale. Month names for locales other than
`en_US` need `await initializeDateFormatting('de_DE');` from
`package:intl/date_symbol_data_local.dart` once at startup.

**Boxes instead of letters**
The text uses a script the bundled font doesn't have (e.g. Devanagari). Add
a font with `InvoiceTheme(fontFallback: [...])`; see [Fonts](#fonts).

**`Logo asset … could not be loaded`**
List the file under `flutter: assets:` in your app's `pubspec.yaml`.

**Network logo fails on the web**
The image server must allow cross-origin requests (CORS). Use
`InvoiceLogo.memory` or `.asset` instead.

**I can't find the saved file on Android/iOS**
The app documents folder is private. Use `share` to let the user save it
anywhere.

**Build error in `package:image` mentioning `decodeLazy`**
A known incompatibility between `pdf` 3.12.x and `image` 4.11.0 (an upstream
bug). Run `flutter pub upgrade pdf image`.

---

## Roadmap

- Custom templates and custom sections
- Tax-inclusive prices
- Recurring invoices and credit notes
- Generation in a background isolate for very large invoices
- More templates

Ideas and bug reports are welcome in the issue tracker.

---

## License

MIT. The bundled Noto Sans fonts are under the SIL Open Font License 1.1.
