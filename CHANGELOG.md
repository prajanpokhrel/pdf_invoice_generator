# Changelog

All notable changes to this package are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package uses
[Semantic Versioning](https://semver.org/).

## 0.1.0

First public release.

### Added

- **Models:** `Invoice`, `InvoiceItem`, `Business`, `Customer`, `Tax`,
  `Discount`, `Currency` (USD, EUR, GBP, INR, NPR, AUD, CAD, JPY + custom),
  `PaymentInformation`, `InvoiceLogo` (memory / asset / network),
  `InvoiceDetail`, `InvoiceQrCode`. All immutable with value equality and
  `copyWith`.
- **Calculation:** `InvoiceCalculator.calculate()` returning `InvoiceTotals`.
  Exact decimal arithmetic (no floating-point drift), round half away from
  zero to the currency's decimals, multiple taxes, item-level taxes and
  discounts, invoice discount shared across lines by largest remainder.
- **Validation:** `InvoiceValidator` reporting every problem at once through
  `InvoiceValidationException`.
- **PDF:** `InvoiceGenerator.generate()` returning `InvoicePdf`. A4 and Letter,
  multi-page tables with repeated headers, "Page X of Y", continuation header.
- **Templates:** `InvoiceTemplate.classic`, `.modern` and `.minimal`.
- **Customization:** `InvoiceTheme` (colours, fonts, font fallback, sizes,
  spacing, border radius, table style, logo / page number / footer toggles,
  locale, date format), `InvoiceTableStyle`, `InvoiceLabels` (translate every
  word), `InvoiceFormatter`.
- **Fonts:** bundled Noto Sans (OFL) covering Latin, Greek, Cyrillic and
  currency symbols such as ₹ — works fully offline.
- **Preview:** `InvoicePreview` widget showing the real PDF, regenerating only
  when inputs change.
- **Output:** `InvoiceGenerator.print/share/save` and `InvoicePdf.print/share/save`,
  `InvoiceSaveResult`, `InvoiceOutputException`. Web downloads instead of
  writing files.
- **Example app:** Invoice Studio in `example/`.
