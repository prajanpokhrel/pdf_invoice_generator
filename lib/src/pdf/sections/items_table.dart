// Internal: the items table, shared by all templates.
//
// The table is a SpanningWidget: when it does not fit on one page, the
// MultiPage layout continues it on the next page and repeats the header row
// (TableRow(repeat: true)).

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../calculation/invoice_totals.dart';
import '../../models/discount.dart';
import '../render_context.dart';

/// How a template wants the items table to look.
final class ItemsTableStyle {
  /// Creates a style.
  const ItemsTableStyle({
    required this.headerBackground,
    required this.headerTextColor,
    this.stripeColor,
    this.border,
    this.rowDivider,
    this.cellPadding =
        const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
  });

  /// Background of the header row.
  final PdfColor? headerBackground;

  /// Text colour of the header row.
  final PdfColor headerTextColor;

  /// Background of every second body row, or `null` for none.
  final PdfColor? stripeColor;

  /// Full table border, or `null`.
  final pw.TableBorder? border;

  /// Line under each body row, or `null`.
  final pw.BorderSide? rowDivider;

  /// Padding inside every cell.
  final pw.EdgeInsets cellPadding;
}

final class _Column {
  const _Column(this.title, this.flex, this.align, this.cell);
  final String title;
  final double flex;
  final pw.Alignment align;
  final pw.Widget Function(InvoiceLineTotals line) cell;
}

/// Builds the items table for [ctx] in the given [style].
pw.Widget itemsTable(RenderContext ctx, ItemsTableStyle style) {
  final f = ctx.formatter;
  final l = ctx.labels;

  pw.Widget text(String value, {pw.TextStyle? style}) =>
      pw.Text(value, style: style ?? ctx.body);

  final columns = <_Column>[
    _Column(l.item, 4, pw.Alignment.centerLeft, (line) {
      final item = line.item;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          text(item.name, style: ctx.bold),
          if (item.description != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: text(item.description!, style: ctx.muted),
            ),
          if (item.sku != null) text('${l.sku}: ${item.sku}', style: ctx.muted),
        ],
      );
    }),
    _Column(l.quantity, 1.2, pw.Alignment.centerRight, (line) {
      final unit = line.item.unit;
      final qty = f.quantity(line.item.quantity);
      return text(unit == null ? qty : '$qty $unit');
    }),
    _Column(
      l.unitPrice,
      1.7,
      pw.Alignment.centerRight,
      (line) => text(f.money(line.item.unitPrice)),
    ),
    if (ctx.showDiscountColumn)
      _Column(l.discount, 1.5, pw.Alignment.centerRight, (line) {
        final d = line.item.discount;
        if (d == null) return text('-', style: ctx.muted);
        return text(
          d.type == DiscountType.percentage
              ? f.percent(d.value)
              : f.money(line.discountAmount),
        );
      }),
    if (ctx.showTaxColumn)
      _Column(l.tax, 1.3, pw.Alignment.centerRight, (line) {
        if (line.taxes.isEmpty) return text(l.taxExempt, style: ctx.muted);
        return text(line.taxes.map((t) => f.percent(t.percentage)).join(' + '));
      }),
    _Column(
      l.amount,
      1.8,
      pw.Alignment.centerRight,
      (line) => text(f.money(line.lineTotal), style: ctx.bold),
    ),
  ];

  pw.Widget cell(pw.Widget child, pw.Alignment align) => pw.Container(
        padding: style.cellPadding,
        alignment: align,
        child: child,
      );

  final header = pw.TableRow(
    repeat: true,
    decoration: style.headerBackground == null
        ? null
        : pw.BoxDecoration(color: style.headerBackground),
    children: [
      for (final c in columns)
        cell(
          pw.Text(
            c.title,
            style: ctx.bold.copyWith(color: style.headerTextColor),
          ),
          c.align,
        ),
    ],
  );

  final rows = <pw.TableRow>[
    for (var i = 0; i < ctx.totals.lines.length; i++)
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.top,
        decoration: pw.BoxDecoration(
          color:
              style.stripeColor != null && i.isOdd ? style.stripeColor : null,
          border: style.rowDivider == null
              ? null
              : pw.Border(bottom: style.rowDivider!),
        ),
        children: [
          for (final c in columns) cell(c.cell(ctx.totals.lines[i]), c.align),
        ],
      ),
  ];

  return pw.Table(
    border: style.border,
    columnWidths: {
      for (var i = 0; i < columns.length; i++)
        i: pw.FlexColumnWidth(columns[i].flex),
    },
    children: [header, ...rows],
  );
}
