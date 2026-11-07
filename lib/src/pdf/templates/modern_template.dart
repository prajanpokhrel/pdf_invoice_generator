// Internal: the Modern template (startup / SaaS style).
//
// Layout (page 1):
//   +--------------------------------------------------------------+
//   | [logo] Seller name                               INVOICE     |  <- primary
//   |        address / email                           INV-1001    |     band
//   +--------------------------------------------------------------+
//   BILL TO            Issue date  Nov 7, 2026     +--------------+
//   Customer name      Due date    Dec 7, 2026     | AMOUNT DUE   |
//   lines              PO Number   PO-7781         | Rs. 915.30   |
//                                                  +--------------+
//   Item            Qty   Unit price        Amount   <- tinted header
//   ...  (striped rows, no grid)
//                                      +-----------------------+
//                                      | Subtotal       900.00 |  <- card
//                                      | [Total         915.30]|
//                                      +-----------------------+
//   PAYMENT DETAILS [QR] / NOTES / TERMS / Thank you

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../render_context.dart';
import '../sections/footer_section.dart';
import '../sections/items_table.dart';
import '../sections/party_section.dart';
import '../sections/summary_section.dart';
import 'template_renderer.dart';

/// Light text on the coloured band.
const _onPrimaryMuted = PdfColor.fromInt(0xFFE0E7FF);

/// Very light grey for stripes and cards.
const _surface = PdfColor.fromInt(0xFFF8FAFC);

/// Modern startup/SaaS-style invoice.
final class ModernTemplate implements TemplateRenderer {
  /// Creates the template.
  const ModernTemplate();

  @override
  List<pw.Widget> buildContent(RenderContext ctx) => [
        _band(ctx),
        ctx.gap(1.2),
        _infoRow(ctx),
        ctx.gap(1.3),
        itemsTable(
          ctx,
          ItemsTableStyle(
            headerBackground: ctx.primaryTint,
            headerTextColor: ctx.theme.primaryColor,
            stripeColor: _surface,
            borderColor: ctx.lineColor,
            showRowDividers: false,
            rowPadding: 6,
          ),
        ),
        ctx.gap(),
        summaryBox(
          ctx,
          width: 240,
          background: _surface,
          totalBackground: ctx.theme.primaryColor,
          totalTextColor: PdfColors.white,
          radius: ctx.theme.borderRadius,
        ),
        ctx.gap(1.5),
        ...closingSections(ctx),
      ];

  @override
  pw.Widget buildPageHeader(RenderContext ctx, pw.Context page) =>
      continuationHeader(ctx, page);

  @override
  pw.Widget buildPageFooter(RenderContext ctx, pw.Context page) =>
      pageFooter(ctx, page);

  pw.BorderRadius? _radius(RenderContext ctx) => ctx.theme.borderRadius > 0
      ? pw.BorderRadius.all(pw.Radius.circular(ctx.theme.borderRadius))
      : null;

  pw.Widget _band(RenderContext ctx) {
    final seller = ctx.invoice.seller;
    final logo = logoBox(ctx, maxHeight: 40, maxWidth: 120);
    final white = ctx.body.copyWith(color: PdfColors.white);
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: ctx.theme.primaryColor,
        borderRadius: _radius(ctx),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            // White tile so any logo stays readable on the coloured band.
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: _radius(ctx),
              ),
              child: logo,
            ),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  seller.name,
                  style: white.copyWith(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: ctx.theme.baseFontSize * 1.5,
                  ),
                ),
                pw.SizedBox(height: 3),
                for (final line in businessLines(ctx, seller))
                  pw.Text(
                    line,
                    style: white.copyWith(
                      color: _onPrimaryMuted,
                      fontSize: ctx.theme.baseFontSize * 0.9,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                ctx.labels.invoiceTitle,
                style: white.copyWith(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: ctx.theme.baseFontSize * 2.2,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                ctx.invoice.invoiceNumber,
                style: white.copyWith(color: _onPrimaryMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(RenderContext ctx) {
    final inv = ctx.invoice;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: partyBlock(
            ctx,
            title: ctx.labels.billTo,
            name: inv.customer.name,
            lines: customerLines(ctx, inv.customer),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(flex: 3, child: metaTable(ctx)),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: ctx.primaryTint,
              borderRadius: _radius(ctx),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(ctx.labels.amountDue.toUpperCase(), style: ctx.caption),
                pw.SizedBox(height: 4),
                pw.Text(
                  ctx.formatter.money(ctx.totals.total),
                  style: ctx.bold.copyWith(
                    fontSize: ctx.theme.baseFontSize * 1.8,
                    color: ctx.theme.primaryColor,
                  ),
                ),
                if (inv.dueDate != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${ctx.labels.dueDate}: '
                    '${ctx.formatter.date(inv.dueDate!)}',
                    style: ctx.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
