// Internal: seller / customer text blocks, shared by all templates.

import 'package:pdf/widgets.dart' as pw;

import '../../models/business.dart';
import '../../models/customer.dart';
import '../render_context.dart';

/// Contact lines for the seller, without the name.
List<String> businessLines(RenderContext ctx, Business b) => [
      if (b.address != null) ...b.address!.split('\n'),
      if (b.phone != null) b.phone!,
      if (b.email != null) b.email!,
      if (b.website != null) b.website!,
      if (b.taxId != null) '${ctx.labels.taxId}: ${b.taxId}',
      if (b.registrationNumber != null)
        '${ctx.labels.registrationNumber}: ${b.registrationNumber}',
    ];

/// Contact lines for the customer, without the name.
List<String> customerLines(RenderContext ctx, Customer c) => [
      if (c.companyName != null) c.companyName!,
      if (c.address != null) ...c.address!.split('\n'),
      if (c.phone != null) c.phone!,
      if (c.email != null) c.email!,
      if (c.taxId != null) '${ctx.labels.taxId}: ${c.taxId}',
    ];

/// A name in bold followed by muted [lines], with an optional [title].
pw.Widget partyBlock(
  RenderContext ctx, {
  required String name,
  required List<String> lines,
  String? title,
  pw.TextStyle? nameStyle,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        pw.Text(title.toUpperCase(), style: ctx.caption),
        pw.SizedBox(height: 4),
      ],
      pw.Text(name, style: nameStyle ?? ctx.bold),
      pw.SizedBox(height: 2),
      for (final line in lines) pw.Text(line, style: ctx.muted),
    ],
  );
}

/// Invoice number, dates and custom details as label/value rows.
List<(String, String)> invoiceMetaRows(RenderContext ctx) {
  final inv = ctx.invoice;
  return [
    (ctx.labels.invoiceNumber, inv.invoiceNumber),
    (ctx.labels.issueDate, ctx.formatter.date(inv.issueDate)),
    if (inv.dueDate != null)
      (ctx.labels.dueDate, ctx.formatter.date(inv.dueDate!)),
    for (final d in inv.details) (d.label, d.value),
  ];
}
