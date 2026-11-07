/// Create professional invoice PDFs in Flutter with a few lines of code.
///
/// ```dart
/// final pdf = await InvoiceGenerator.generate(invoice);
/// ```
library;

// Types from package:pdf that appear in this package's API, re-exported so
// users do not need to import package:pdf themselves.
export 'package:pdf/pdf.dart' show PdfColor, PdfColors, PdfPageFormat;
export 'package:pdf/widgets.dart' show Font;

// Exports are sorted alphabetically (lint: directives_ordering).
export 'src/calculation/invoice_calculator.dart';
export 'src/calculation/invoice_totals.dart';
export 'src/exceptions/invoice_exceptions.dart';
export 'src/formatting/invoice_formatter.dart';
export 'src/models/business.dart';
export 'src/models/currency.dart';
export 'src/models/customer.dart';
export 'src/models/discount.dart';
export 'src/models/invoice.dart';
export 'src/models/invoice_detail.dart';
export 'src/models/invoice_item.dart';
// Only the base type is public; the concrete logo classes are internal.
export 'src/models/invoice_logo.dart' show InvoiceLogo;
export 'src/models/payment_information.dart';
export 'src/models/tax.dart';
export 'src/pdf/invoice_generator.dart' show InvoiceGenerator;
export 'src/pdf/invoice_labels.dart';
export 'src/pdf/invoice_pdf.dart';
export 'src/pdf/invoice_theme.dart';
export 'src/pdf/templates/invoice_template.dart' show InvoiceTemplate;
export 'src/validation/invoice_validator.dart';
