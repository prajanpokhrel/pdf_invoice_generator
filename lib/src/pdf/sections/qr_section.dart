// Internal: the optional QR code block, shared by all templates.

import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_qr_code.dart';
import '../render_context.dart';

/// The QR code with its caption, or `null` when the invoice has none.
pw.Widget? qrBlock(RenderContext ctx, {double size = 76}) {
  final qr = ctx.invoice.qrCode;
  if (qr == null) return null;
  final caption = qr.caption ??
      switch (qr.type) {
        InvoiceQrCodeType.payment => ctx.labels.scanToPay,
        InvoiceQrCodeType.invoiceUrl => ctx.labels.scanToView,
        InvoiceQrCodeType.custom => '',
      };
  return pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: qr.data,
        width: size,
        height: size,
        color: ctx.theme.textColor,
        drawText: false,
      ),
      if (caption.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Text(caption, style: ctx.muted),
      ],
    ],
  );
}
