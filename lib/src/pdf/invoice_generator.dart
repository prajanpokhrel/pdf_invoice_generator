import 'dart:ui' show Rect;

import 'package:pdf/widgets.dart' as pw;

import '../calculation/invoice_calculator.dart';
import '../exceptions/invoice_exceptions.dart';
import '../formatting/invoice_formatter.dart';
import '../models/invoice.dart';
import '../output/invoice_output.dart';
import 'invoice_labels.dart';
import 'invoice_pdf.dart';
import 'invoice_theme.dart';
import 'render_context.dart';
import 'resources/font_loader.dart';
import 'resources/logo_loader.dart';
import 'templates/invoice_template.dart';
import 'templates/template_renderer.dart';

/// Generates invoice PDFs, and prints, shares or saves them.
///
/// ```dart
/// final pdf = await InvoiceGenerator.generate(invoice);
/// await InvoiceGenerator.print(invoice);
/// await InvoiceGenerator.share(invoice);
/// final saved = await InvoiceGenerator.save(invoice);
/// ```
///
/// `print`, `share` and `save` generate the PDF first. If you already have
/// an [InvoicePdf], call `pdf.print()`, `pdf.share()` or `pdf.save()`
/// instead (see [InvoicePdfActions]).
///
/// Generation works fully offline, except when the seller logo is an
/// `InvoiceLogo.network`.
abstract final class InvoiceGenerator {
  /// Safety limit on pages. Far more than any real invoice needs; it only
  /// protects against layout bugs looping forever.
  static const int _maxPages = 1000;

  /// Builds the PDF for [invoice].
  ///
  /// * [template] chooses the layout (default [InvoiceTemplate.classic]).
  /// * [theme] sets page size, colours, fonts and formats.
  /// * [labels] sets every fixed word (translate here).
  ///
  /// Long invoices automatically continue on new pages, with the table
  /// header repeated and "Page X of Y" in the footer.
  ///
  /// Throws:
  /// * [InvoiceValidationException] when the invoice data is invalid.
  /// * [InvoiceImageException] when the logo cannot be loaded or decoded.
  /// * [InvoiceGenerationException] for any other failure.
  static Future<InvoicePdf> generate(
    Invoice invoice, {
    InvoiceTemplate template = InvoiceTemplate.classic,
    InvoiceTheme theme = const InvoiceTheme(),
    InvoiceLabels labels = const InvoiceLabels(),
  }) async {
    // 1. Validate + calculate (throws InvoiceValidationException).
    final totals = InvoiceCalculator.calculate(invoice);

    try {
      // 2. Resources (async: assets, network, fonts).
      final logo = await loadLogo(invoice.seller.logo);
      final fontTheme = await resolveFontTheme(theme);

      // 3. Layout.
      final ctx = RenderContext(
        invoice: invoice,
        totals: totals,
        theme: theme,
        labels: labels,
        formatter: InvoiceFormatter(
          currency: invoice.currency,
          locale: theme.locale,
          datePattern: theme.dateFormat,
        ),
        logo: logo,
      );
      final renderer = rendererFor(template);
      final document = pw.Document(
        theme: fontTheme,
        title: '${labels.invoiceTitle} ${invoice.invoiceNumber}',
        author: invoice.seller.name,
        creator: 'flutter_invoice_generator',
        subject: invoice.customer.name,
      );
      document.addPage(
        pw.MultiPage(
          pageFormat: theme.pageFormat,
          margin: pw.EdgeInsets.all(theme.margin),
          maxPages: _maxPages,
          header: (page) => renderer.buildPageHeader(ctx, page),
          footer: (page) => renderer.buildPageFooter(ctx, page),
          build: (_) => renderer.buildContent(ctx),
        ),
      );

      // 4. Serialize.
      final bytes = await document.save();
      return InvoicePdf(
        bytes: bytes,
        fileName: fileNameFor(invoice.invoiceNumber),
        pageCount: document.document.pdfPageList.pages.length,
        totals: totals,
        pageFormat: theme.pageFormat,
      );
    } on InvoiceException {
      rethrow;
    } on Object catch (e, stackTrace) {
      throw InvoiceGenerationException(
        'Could not generate the PDF for invoice "${invoice.invoiceNumber}": '
        '$e',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Generates the PDF and opens the system print dialog.
  ///
  /// Returns `false` when the user cancelled. See [InvoicePdfActions.print].
  static Future<bool> print(
    Invoice invoice, {
    InvoiceTemplate template = InvoiceTemplate.classic,
    InvoiceTheme theme = const InvoiceTheme(),
    InvoiceLabels labels = const InvoiceLabels(),
    String? jobName,
  }) async {
    final pdf = await generate(
      invoice,
      template: template,
      theme: theme,
      labels: labels,
    );
    return pdf.print(jobName: jobName);
  }

  /// Generates the PDF and opens the platform share UI.
  ///
  /// See [InvoicePdfActions.share] for what this does on each platform.
  static Future<bool> share(
    Invoice invoice, {
    InvoiceTemplate template = InvoiceTemplate.classic,
    InvoiceTheme theme = const InvoiceTheme(),
    InvoiceLabels labels = const InvoiceLabels(),
    String? subject,
    String? text,
    List<String>? emails,
    Rect? sharePositionOrigin,
  }) async {
    final pdf = await generate(
      invoice,
      template: template,
      theme: theme,
      labels: labels,
    );
    return pdf.share(
      subject: subject,
      text: text,
      emails: emails,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Generates the PDF and saves it as a file (a download on the web).
  ///
  /// See [InvoicePdfActions.save] for where the file goes.
  static Future<InvoiceSaveResult> save(
    Invoice invoice, {
    InvoiceTemplate template = InvoiceTemplate.classic,
    InvoiceTheme theme = const InvoiceTheme(),
    InvoiceLabels labels = const InvoiceLabels(),
    String? directory,
    String? fileName,
  }) async {
    final pdf = await generate(
      invoice,
      template: template,
      theme: theme,
      labels: labels,
    );
    return pdf.save(directory: directory, fileName: fileName);
  }

  /// `INV/2026 #1` -> `INV_2026__1.pdf`.
  static String fileNameFor(String invoiceNumber) {
    final safe =
        invoiceNumber.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return '${safe.isEmpty ? 'invoice' : safe}.pdf';
  }
}
