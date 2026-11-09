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

/// Paragraphs up to this length are kept together with a heading or the
/// thank-you line. Longer ones flow freely across pages.
const _shortParagraph = 600;

/// [text] as top-level widgets that may continue on the next page.
///
/// Why this matters: the pdf library keeps adding pages when a block that
/// cannot be split is taller than a page, and only a debug-mode assert stops
/// it. In a release build that would freeze the app. Text with
/// `TextOverflow.span`, placed directly in the page content (not inside a
/// Column), always makes progress, so very long notes or terms simply
/// continue on the next page.
List<pw.Widget> flowingText(String text, pw.TextStyle style) => [
      for (final paragraph in text.split('\n'))
        paragraph.trim().isEmpty
            ? pw.SizedBox(height: style.fontSize ?? 8)
            : pw.Text(paragraph, style: style, overflow: pw.TextOverflow.span),
    ];

/// Payment details (with the QR code beside them), payment instructions,
/// notes, terms and the thank-you line.
///
/// * Every text that can be long flows across pages (see [flowingText]).
/// * A heading stays with its first paragraph when that paragraph is short.
/// * The thank-you line is attached to the last short block, so it is never
///   left alone at the top of an otherwise empty page.
List<pw.Widget> closingSections(RenderContext ctx) {
  final inv = ctx.invoice;
  final l = ctx.labels;
  final out = <pw.Widget>[];
  // Index in [out] of the last block that is small enough to be kept
  // together with the thank-you line.
  int? lastShortBlock;

  pw.Widget heading(String title) =>
      pw.Text(title.toUpperCase(), style: ctx.caption);

  void textSection(String? title, String text, pw.TextStyle style) {
    final paragraphs = flowingText(text, style);
    if (paragraphs.isEmpty) return;
    final first = text.split('\n').first;
    if (first.length <= _shortParagraph) {
      out.add(
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (title != null) ...[heading(title), pw.SizedBox(height: 4)],
              paragraphs.first,
            ],
          ),
        ),
      );
    } else {
      if (title != null) out.addAll([heading(title), pw.SizedBox(height: 4)]);
      out.add(paragraphs.first);
    }
    out.addAll(paragraphs.skip(1));
    final last = text.split('\n').last;
    lastShortBlock = last.length <= _shortParagraph ? out.length - 1 : null;
  }

  // 1. Payment details + QR code: a fixed-size block.
  final payment = paymentRows(ctx);
  final instructions = inv.paymentInformation?.instructions;
  final qr = qrBlock(ctx);
  final hasPayment = payment.isNotEmpty || instructions != null;
  if (hasPayment || qr != null) {
    out.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: !hasPayment
                ? pw.SizedBox()
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      heading(l.paymentInformation),
                      pw.SizedBox(height: 4),
                      for (final (label, value) in payment)
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: '$label: ', style: ctx.muted),
                              pw.TextSpan(text: value, style: ctx.body),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          if (qr != null)
            pw.Padding(padding: const pw.EdgeInsets.only(left: 16), child: qr),
        ],
      ),
    );
    lastShortBlock = out.length - 1;
    if (instructions != null) {
      out.add(pw.SizedBox(height: 3));
      textSection(null, instructions, ctx.body);
    }
    out.add(pw.SizedBox(height: 10));
  }

  // 2. Notes and terms: may be long, so they flow.
  if (inv.notes != null) {
    textSection(l.notes, inv.notes!, ctx.body);
    out.add(pw.SizedBox(height: 10));
  }
  if (inv.terms != null) {
    textSection(l.terms, inv.terms!, ctx.muted);
    out.add(pw.SizedBox(height: 10));
  }

  // 3. Thank-you line, glued to the last short block when there is one.
  final thankYou = l.thankYou;
  if (thankYou != null) {
    final line = pw.Text(
      thankYou,
      style: ctx.bold.copyWith(color: ctx.theme.primaryColor),
    );
    final index = lastShortBlock;
    if (index == null) {
      out.add(line);
    } else {
      out[index] = pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [out[index], pw.SizedBox(height: 16), line],
        ),
      );
    }
  }
  return out;
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
