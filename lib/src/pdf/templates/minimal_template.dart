// Internal: the Minimal template.
//
// Layout (page 1):
//   Seller name                                              [logo]
//   address / email
//
//   I N V O I C E
//   BILL TO                                  Invoice No.  INV-1001
//   Customer name / lines                    Issue date   Nov 7, 2026
//
//   ITEM            QTY    UNIT PRICE         AMOUNT
//   ______________________________________________________  <- dark line
//   Flutter App Development    1   500.00     500.00
//   ------------------------------------------------------  <- hairlines
//                                      Subtotal       900.00
//                                      ______________________
//                                      Total          915.30
//   PAYMENT DETAILS [QR] / NOTES / TERMS / Thank you
//
// No fills, thin lines, generous white space. The primary colour is only
// used for the grand total and the thank-you line.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../render_context.dart';
import '../sections/footer_section.dart';
import '../sections/items_table.dart';
import '../sections/party_section.dart';
import '../sections/summary_section.dart';
import 'template_renderer.dart';

/// Simple, clean invoice.
final class MinimalTemplate implements TemplateRenderer {
  /// Creates the template.
  const MinimalTemplate();

  @override
  List<pw.Widget> buildContent(RenderContext ctx) => [
        _header(ctx),
        ctx.gap(1.6),
        pw.Text(
          ctx.labels.invoiceTitle,
          style: ctx.body.copyWith(
            fontSize: ctx.theme.baseFontSize * 1.6,
            color: ctx.theme.secondaryColor,
            letterSpacing: 4,
          ),
        ),
        ctx.gap(0.8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: partyBlock(
                ctx,
                title: ctx.labels.billTo,
                name: ctx.invoice.customer.name,
                lines: customerLines(ctx, ctx.invoice.customer),
              ),
            ),
            pw.SizedBox(width: 24),
            metaTable(ctx, valueStyle: ctx.body),
          ],
        ),
        ctx.gap(1.6),
        itemsTable(
          ctx,
          ItemsTableStyle(
            headerTextColor: ctx.theme.secondaryColor,
            headerUnderline: ctx.theme.textColor,
            borderColor: const PdfColor.fromInt(0xFFE2E8F0),
            rowPadding: 6,
          ),
        ),
        ctx.gap(),
        summaryBox(
          ctx,
          totalTopBorder: ctx.theme.textColor,
          totalTextColor: ctx.theme.primaryColor,
        ),
        ctx.gap(1.8),
        ...closingSections(ctx),
      ];

  @override
  pw.Widget buildPageHeader(RenderContext ctx, pw.Context page) =>
      continuationHeader(ctx, page);

  @override
  pw.Widget buildPageFooter(RenderContext ctx, pw.Context page) =>
      pageFooter(ctx, page);

  pw.Widget _header(RenderContext ctx) {
    final seller = ctx.invoice.seller;
    final logo = logoBox(ctx, maxHeight: 40, maxWidth: 120);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: partyBlock(
            ctx,
            name: seller.name,
            lines: businessLines(ctx, seller),
            nameStyle:
                ctx.bold.copyWith(fontSize: ctx.theme.baseFontSize * 1.2),
          ),
        ),
        if (logo != null) logo,
      ],
    );
  }
}
