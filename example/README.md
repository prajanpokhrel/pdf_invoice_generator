# Invoice Studio — flutter_invoice_generator example

A complete demo of the package: edit an invoice and watch the real PDF update.

| Feature | Where in the code |
|---|---|
| Build an `Invoice` from form fields | `lib/src/invoice_draft.dart` → `toInvoice()` |
| Business, customer, items (add/remove), discount, tax, currency, template, colour, paper | `lib/src/editor_panel.dart` |
| Live preview (`InvoicePreview`), debounced while typing | `lib/src/home_page.dart` |
| Share / Print / Save the PDF that is on screen | `lib/src/home_page.dart` (`pdf.share()`, `pdf.print()`, `pdf.save()`) |
| Validation messages from `InvoiceValidator` | `lib/src/home_page.dart` (`_IssuesBanner`) |

Wide screens show the editor and preview side by side; phones get
**Edit / Preview** tabs.

## Run

```bash
cd example
flutter run -d macos     # or: chrome, windows, linux, an Android/iOS device
```

macOS: printing needs the `com.apple.security.print` entitlement — already
added in `macos/Runner/*.entitlements`.

## Tests

```bash
flutter test                          # unit + widget tests
flutter test integration_test -d macos  # runs inside the real app
```

The integration test checks that the native plugin really renders the
pages, that switching templates updates the preview, and that `save()`
writes a file. It also saves screenshots to the app's temp folder.
