// Internal: the Classic template.
//
// Layout (page 1):
//   [logo] Seller name                       INVOICE
//          address / phone / email   Invoice No.  INV-1001
//                                    Issue date   Nov 7, 2026
//   ------------------------------------------------------------
//   BILL TO
//   Customer name / lines
//   | Item | Qty | Unit price | (Discount) | (Tax) | Amount |   <- coloured
//   | ...                                                    |   <- grid
//                                           Subtotal   700.00
//                                           Discount   -70.00
//                                           VAT (13%)   81.90
//                                           [ Total    711.90 ]
//   PAYMENT DETAILS [QR] / NOTES / TERMS / Thank you

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../render_context.dart';
import '../sections/footer_section.dart';
import '../sections/items_table.dart';
import '../sections/party_section.dart';
import '../sections/summary_section.dart';
import 'template_renderer.dart';

/// Traditional professional invoice.
final class ClassicTemplate implements TemplateRenderer {
  /// Creates the template.
  const ClassicTemplate();

  @override
  List<pw.Widget> buildContent(RenderContext ctx) => [
        _header(ctx),
        ctx.gap(0.7),
        pw.Divider(color: ctx.theme.secondaryColor, thickness: 0.5),
        ctx.gap(0.5),
        // Kept in one piece: a Column at the top level could otherwise make
        // the page layout loop when one line is taller than a page.
        pw.Inseparable(
          child: partyBlock(
            ctx,
            title: ctx.labels.billTo,
            name: ctx.invoice.customer.name,
            lines: customerLines(ctx, ctx.invoice.customer),
          ),
        ),
        ctx.gap(),
        itemsTable(
          ctx,
          ItemsTableStyle(
            headerBackground: ctx.theme.primaryColor,
            headerTextColor: PdfColors.white,
            borderColor: ctx.lineColor,
            showGrid: true,
          ),
        ),
        ctx.gap(0.85),
        summaryBox(
          ctx,
          totalBackground: ctx.theme.primaryColor,
          totalTextColor: PdfColors.white,
        ),
        ctx.gap(1.3),
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
    final logo = logoBox(ctx);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null) ...[logo, pw.SizedBox(height: 8)],
              partyBlock(
                ctx,
                name: seller.name,
                lines: businessLines(ctx, seller),
                nameStyle:
                    ctx.bold.copyWith(fontSize: ctx.theme.baseFontSize * 1.4),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              ctx.labels.invoiceTitle,
              style: ctx.bold.copyWith(
                fontSize: ctx.theme.baseFontSize * 2.6,
                color: ctx.theme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 8),
            metaTable(ctx),
          ],
        ),
      ],
    );
  }
}
