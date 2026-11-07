/// Create professional invoice PDFs in Flutter with a few lines of code.
///
/// Start with [Invoice], then generate a PDF with `InvoiceGenerator`
/// (available from Phase 4).
library;

// Exports are sorted alphabetically (lint: directives_ordering).
export 'src/calculation/invoice_calculator.dart';
export 'src/calculation/invoice_totals.dart';
export 'src/exceptions/invoice_exceptions.dart';
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
export 'src/validation/invoice_validator.dart';
