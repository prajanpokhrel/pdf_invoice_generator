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

/// How a template wants the items table to look. The theme's
/// `InvoiceTableStyle` can override each field (see [resolve]).
final class ItemsTableStyle {
  /// Creates a style.
  const ItemsTableStyle({
    required this.headerTextColor,
    required this.borderColor,
    this.headerBackground,
    this.headerUnderline,
    this.stripeColor,
    this.showGrid = false,
    this.showRowDividers = true,
    this.rowPadding = 4.5,
  });

  /// Background of the header row, or `null` for none.
  final PdfColor? headerBackground;

  /// Text colour of the header row.
  final PdfColor headerTextColor;

  /// A line under the header row, or `null` for none.
  final PdfColor? headerUnderline;

  /// Background of every second body row, or `null` for none.
  final PdfColor? stripeColor;

  /// Colour of the grid and row dividers.
  final PdfColor borderColor;

  /// Full grid around every cell.
  final bool showGrid;

  /// Thin line under each item (always drawn when [showGrid] is on).
  final bool showRowDividers;

  /// Vertical padding inside each cell.
  final double rowPadding;

  /// This style with the theme's overrides applied.
  ItemsTableStyle resolve(RenderContext ctx) {
    final o = ctx.theme.tableStyle;
    return ItemsTableStyle(
      headerBackground: o.headerColor ?? headerBackground,
      headerTextColor: o.headerTextColor ?? headerTextColor,
      headerUnderline: headerUnderline,
      stripeColor: o.stripeColor ?? stripeColor,
      borderColor: o.borderColor ?? borderColor,
      showGrid: o.showBorders ?? showGrid,
      showRowDividers: showRowDividers,
      rowPadding: o.rowPadding ?? rowPadding,
    );
  }
}

final class _Column {
  const _Column(this.title, this.flex, this.align, this.cell);
  final String title;
  final double flex;
  final pw.Alignment align;
  final pw.Widget Function(InvoiceLineTotals line) cell;
}

/// Builds the items table for [ctx] in the template's [defaults], with the
/// theme's table overrides applied.
pw.Widget itemsTable(RenderContext ctx, ItemsTableStyle defaults) {
  final style = defaults.resolve(ctx);
  final f = ctx.formatter;
  final l = ctx.labels;

  pw.Widget text(String value, {pw.TextStyle? style}) =>
      pw.Text(value, style: style ?? ctx.body);

  final columns = <_Column>[
    _Column(l.item, 4, pw.Alignment.centerLeft, (line) {
      final item = line.item;
      final chunks = descriptionChunks(item.description);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          text(item.name, style: ctx.bold),
          if (chunks.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: text(chunks.first, style: ctx.muted),
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

  final padding = pw.EdgeInsets.symmetric(
    horizontal: 6,
    vertical: style.rowPadding,
  );
  final divider = pw.BorderSide(color: style.borderColor, width: 0.5);

  /// A cell. [joinAbove]/[joinBelow] remove the padding between the rows of
  /// one item whose description continues, so it reads as one block.
  pw.Widget cell(
    pw.Widget child,
    pw.Alignment align, {
    bool joinAbove = false,
    bool joinBelow = false,
  }) =>
      pw.Container(
        padding: padding.copyWith(
          top: joinAbove ? 0 : padding.top,
          bottom: joinBelow ? 0 : padding.bottom,
        ),
        alignment: align,
        child: child,
      );

  final header = pw.TableRow(
    repeat: true,
    decoration: pw.BoxDecoration(
      color: style.headerBackground,
      border: style.headerUnderline == null
          ? null
          : pw.Border(
              bottom: pw.BorderSide(color: style.headerUnderline!, width: 1),
            ),
    ),
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

  final rows = <pw.TableRow>[];
  for (var i = 0; i < ctx.totals.lines.length; i++) {
    final line = ctx.totals.lines[i];
    final extra = descriptionChunks(line.item.description).skip(1).toList();
    // Every row of one item shares its stripe colour; the divider goes
    // under the item's last row only.
    pw.BoxDecoration decoration({required bool last}) => pw.BoxDecoration(
          color:
              style.stripeColor != null && i.isOdd ? style.stripeColor : null,
          // Grid mode draws its horizontal lines here too (not as
          // horizontalInside), so the rows of one item are not separated.
          border: last && (style.showRowDividers || style.showGrid)
              ? pw.Border(bottom: divider)
              : null,
        );
    rows.add(
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.top,
        decoration: decoration(last: extra.isEmpty),
        children: [
          for (final c in columns)
            cell(c.cell(line), c.align, joinBelow: extra.isNotEmpty),
        ],
      ),
    );
    for (var k = 0; k < extra.length; k++) {
      rows.add(
        pw.TableRow(
          decoration: decoration(last: k == extra.length - 1),
          children: [
            cell(
              text(extra[k], style: ctx.muted),
              pw.Alignment.centerLeft,
              joinAbove: true,
              joinBelow: k < extra.length - 1,
            ),
            for (var c = 1; c < columns.length; c++) pw.SizedBox(),
          ],
        ),
      );
    }
  }

  return pw.Table(
    border: style.showGrid
        ? pw.TableBorder(
            left: divider,
            top: divider,
            right: divider,
            bottom: divider,
            verticalInside: divider,
          )
        : null,
    columnWidths: {
      for (var i = 0; i < columns.length; i++)
        i: pw.FlexColumnWidth(columns[i].flex),
    },
    children: [header, ...rows],
  );
}

/// Longest piece of a description placed in one table row.
const int maxDescriptionChunk = 350;

/// Most lines (newlines) of a description placed in one table row.
const int maxDescriptionChunkLines = 8;

/// Splits [description] into pieces that each fit comfortably in one table
/// row.
///
/// A table row can never be split across pages. If one row were taller than
/// a page, the pdf library would keep adding pages forever in release builds
/// (only a debug assert stops it). Long descriptions therefore continue in
/// extra rows, so the table can break between them. Pieces are split at line
/// breaks or spaces, and only inside a word when a word itself is too long.
List<String> descriptionChunks(String? description) {
  if (description == null || description.trim().isEmpty) return const [];
  final chunks = <String>[];
  final current = StringBuffer();
  var lines = 0;

  void flush() {
    final text = current.toString().trimRight();
    if (text.isNotEmpty) chunks.add(text);
    current.clear();
    lines = 0;
  }

  void addWord(String word) {
    var rest = word;
    while (rest.length > maxDescriptionChunk) {
      flush();
      chunks.add(rest.substring(0, maxDescriptionChunk));
      rest = rest.substring(maxDescriptionChunk);
    }
    final separator =
        current.isEmpty || current.toString().endsWith('\n') ? '' : ' ';
    if (current.length + separator.length + rest.length > maxDescriptionChunk) {
      flush();
      current.write(rest);
    } else {
      current
        ..write(separator)
        ..write(rest);
    }
  }

  final paragraphs = description.trimRight().split('\n');
  for (var p = 0; p < paragraphs.length; p++) {
    if (p > 0) {
      if (lines + 1 >= maxDescriptionChunkLines ||
          current.length >= maxDescriptionChunk) {
        flush();
      } else {
        current.write('\n');
        lines++;
      }
    }
    for (final word in paragraphs[p].split(' ')) {
      if (word.isEmpty) continue;
      addWord(word);
    }
  }
  flush();
  return chunks;
}
