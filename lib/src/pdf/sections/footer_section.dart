// Internal: notes, payment details and page header/footer, shared by all
// templates.

import 'package:pdf/widgets.dart' as pw;

import '../render_context.dart';
import 'qr_section.dart';

/// Label/value pairs for the payment information that is set.
List<(String, String)> paymentRows(RenderContext ctx) {
  final p = ctx.invoice.paymentInformation;
  if (p == null) return const [];
  final l = ctx.labels;
  return [
    if (p.bankName != null) (l.bankName, p.bankName!),
    if (p.accountName != null) (l.accountName, p.accountName!),
    if (p.accountNumber != null) (l.accountNumber, p.accountNumber!),
    if (p.iban != null) (l.iban, p.iban!),
    if (p.swiftBic != null) (l.swiftBic, p.swiftBic!),
    if (p.routingNumber != null) (l.routingNumber, p.routingNumber!),
    if (p.paymentUrl != null) (l.paymentUrl, p.paymentUrl!),
  ];
}

/// Payment details (with the QR code beside them), notes, terms and the
/// thank-you line, as separate widgets so the page layout can break between
/// them.
///
/// The thank-you line is attached to the last section, so it is never left
/// alone at the top of an otherwise empty page.
List<pw.Widget> closingSections(RenderContext ctx) {
  final sections = _closingSections(ctx);
  final thankYou = ctx.labels.thankYou;
  if (thankYou == null) return sections;
  final line = pw.Padding(
    padding: const pw.EdgeInsets.only(top: 6),
    child: pw.Text(
      thankYou,
      style: ctx.bold.copyWith(color: ctx.theme.primaryColor),
    ),
  );
  if (sections.isEmpty) return [line];
  return [
    ...sections.take(sections.length - 1),
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [sections.last, line],
    ),
  ];
}

List<pw.Widget> _closingSections(RenderContext ctx) {
  final inv = ctx.invoice;
  final l = ctx.labels;
  final payment = paymentRows(ctx);
  final instructions = inv.paymentInformation?.instructions;

  pw.Widget section(String title, List<pw.Widget> children) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title.toUpperCase(), style: ctx.caption),
            pw.SizedBox(height: 4),
            ...children,
          ],
        ),
      );

  final paymentSection = payment.isEmpty && instructions == null
      ? null
      : section(l.paymentInformation, [
          for (final (label, value) in payment)
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: '$label: ', style: ctx.muted),
                  pw.TextSpan(text: value, style: ctx.body),
                ],
              ),
            ),
          if (instructions != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(instructions, style: ctx.body),
            ),
        ]);
  final qr = qrBlock(ctx);

  return [
    if (paymentSection != null || qr != null)
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: paymentSection ?? pw.SizedBox()),
          if (qr != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, bottom: 10),
              child: qr,
            ),
        ],
      ),
    if (inv.notes != null)
      section(l.notes, [pw.Text(inv.notes!, style: ctx.body)]),
    if (inv.terms != null)
      section(l.terms, [pw.Text(inv.terms!, style: ctx.muted)]),
  ];
}

/// Small header on pages 2+, so loose pages can be matched to the invoice.
/// Page 1 already has the full header, so it gets nothing.
pw.Widget continuationHeader(RenderContext ctx, pw.Context page) {
  if (page.pageNumber == 1 || !ctx.theme.showContinuationHeader) {
    return pw.SizedBox();
  }
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: ctx.theme.secondaryColor, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '${ctx.labels.invoiceTitle} ${ctx.invoice.invoiceNumber}',
          style: ctx.bold,
        ),
        pw.Text('(${ctx.labels.continued})', style: ctx.muted),
      ],
    ),
  );
}

/// Footer on every page: footer text (default: seller name) and
/// "Page X of Y", both controlled by the theme.
pw.Widget pageFooter(RenderContext ctx, pw.Context page) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 12),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          ctx.theme.footerText ?? ctx.invoice.seller.name,
          style: ctx.muted,
        ),
        if (ctx.theme.showPageNumbers)
          pw.Text(
            ctx.labels.formatPageOf(page.pageNumber, page.pagesCount),
            style: ctx.muted,
          ),
      ],
    ),
  );
}
