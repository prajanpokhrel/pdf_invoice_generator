// Internal: subtotal / discount / tax / total block, shared by all templates.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/discount.dart';
import '../render_context.dart';

/// One summary line.
final class SummaryRow {
  /// Creates a row.
  const SummaryRow(this.label, this.value, {this.isTotal = false});

  /// Left side, for example `VAT (13%)`.
  final String label;

  /// Right side, formatted money.
  final String value;

  /// Whether this is the grand total (emphasised).
  final bool isTotal;
}

/// The rows to print, read from the pre-calculated totals.
///
/// Discount and tax rows only appear when the invoice has them.
List<SummaryRow> summaryRows(RenderContext ctx) {
  final t = ctx.totals;
  final f = ctx.formatter;
  final l = ctx.labels;
  final discount = ctx.invoice.discount;
  return [
    SummaryRow(l.subtotal, f.money(t.subtotal)),
    if (discount != null)
      SummaryRow(
        [
          discount.label ?? l.discount,
          if (discount.type == DiscountType.percentage)
            '(${f.percent(discount.value)})',
        ].join(' '),
        f.money(-t.discountAmount),
      ),
    for (final tax in t.taxLines)
      SummaryRow(
        '${tax.tax.name} (${f.percent(tax.tax.percentage)})',
        f.money(tax.amount),
      ),
    SummaryRow(l.total, f.money(t.total), isTotal: true),
  ];
}

/// A right-aligned summary box [width] points wide.
///
/// The grand total row uses [totalBackground] and [totalTextColor].
pw.Widget summaryBox(
  RenderContext ctx, {
  double width = 230,
  PdfColor? totalBackground,
  PdfColor? totalTextColor,
  double radius = 0,
}) {
  final rows = summaryRows(ctx);
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.SizedBox(
        width: width,
        child: pw.Column(
          children: [
            for (final row in rows)
              if (row.isTotal)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 6),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: pw.BoxDecoration(
                    color: totalBackground,
                    borderRadius: radius > 0
                        ? pw.BorderRadius.all(pw.Radius.circular(radius))
                        : null,
                  ),
                  child: _line(
                    row,
                    ctx.bold.copyWith(
                      fontSize: ctx.theme.baseFontSize * 1.25,
                      color: totalTextColor ?? ctx.theme.textColor,
                    ),
                  ),
                )
              else
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: _line(row, ctx.body, labelStyle: ctx.muted),
                ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _line(
  SummaryRow row,
  pw.TextStyle style, {
  pw.TextStyle? labelStyle,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(row.label, style: labelStyle ?? style),
      pw.Text(row.value, style: style),
    ],
  );
}
