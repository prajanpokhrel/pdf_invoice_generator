import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../exceptions/invoice_exceptions.dart';
import '../models/invoice.dart';
import '../pdf/invoice_generator.dart';
import '../pdf/invoice_labels.dart';
import '../pdf/invoice_pdf.dart';
import '../pdf/invoice_theme.dart';
import '../pdf/templates/invoice_template.dart';

/// Shows the generated PDF of [invoice] inside your app.
///
/// ```dart
/// InvoicePreview(invoice: invoice, template: InvoiceTemplate.modern)
/// ```
///
/// The preview renders the *real* PDF produced by
/// `InvoiceGenerator.generate`, so it always looks exactly like the file
/// you save, share or print.
///
/// * The PDF is regenerated only when [invoice], [template], [theme] or
///   [labels] change (compared by value), not on every rebuild.
/// * While a new version is being generated, the previous one stays on
///   screen. If several changes arrive quickly, only the latest result is
///   shown.
/// * Invalid data (for example a negative price) shows [errorBuilder]
///   instead of crashing.
///
/// Rendering pages uses the `printing` plugin, which supports Android, iOS,
/// macOS, Windows, Linux and Web.
class InvoicePreview extends StatefulWidget {
  /// Creates a preview.
  const InvoicePreview({
    required this.invoice,
    super.key,
    this.template = InvoiceTemplate.classic,
    this.theme = const InvoiceTheme(),
    this.labels = const InvoiceLabels(),
    this.allowPrinting = false,
    this.allowSharing = false,
    this.maxPageWidth,
    this.backgroundColor,
    this.loadingBuilder,
    this.errorBuilder,
    this.onGenerated,
    this.onError,
  });

  /// The invoice to show.
  final Invoice invoice;

  /// Layout style, see [InvoiceTemplate].
  final InvoiceTemplate template;

  /// Visual settings, see [InvoiceTheme].
  final InvoiceTheme theme;

  /// Fixed words, see [InvoiceLabels].
  final InvoiceLabels labels;

  /// Shows a print button in a toolbar under the preview.
  final bool allowPrinting;

  /// Shows a share button in a toolbar under the preview.
  final bool allowSharing;

  /// Maximum width of a page on screen, in logical pixels.
  final double? maxPageWidth;

  /// Colour behind the pages. Defaults to a light grey.
  final Color? backgroundColor;

  /// Shown until the first PDF is ready. Defaults to a progress indicator.
  final WidgetBuilder? loadingBuilder;

  /// Shown when the PDF cannot be generated. Defaults to a message listing
  /// the problems.
  final Widget Function(BuildContext context, InvoiceException error)?
      errorBuilder;

  /// Called every time a new PDF has been generated, for example to enable
  /// a "Share" button with the same bytes.
  final ValueChanged<InvoicePdf>? onGenerated;

  /// Called when generation fails.
  final ValueChanged<InvoiceException>? onError;

  @override
  State<InvoicePreview> createState() => _InvoicePreviewState();
}

class _InvoicePreviewState extends State<InvoicePreview> {
  InvoicePdf? _pdf;
  InvoiceException? _error;

  /// Handed to PdfPreview. PdfPreview re-renders whenever this function
  /// object changes, so it is replaced only when new bytes arrive.
  LayoutCallback? _build;

  /// Incremented for every generation; results from older runs are ignored.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_generate());
  }

  @override
  void didUpdateWidget(covariant InvoicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice != widget.invoice ||
        oldWidget.template != widget.template ||
        oldWidget.theme != widget.theme ||
        oldWidget.labels != widget.labels) {
      unawaited(_generate());
    }
  }

  Future<void> _generate() async {
    final generation = ++_generation;
    try {
      final pdf = await InvoiceGenerator.generate(
        widget.invoice,
        template: widget.template,
        theme: widget.theme,
        labels: widget.labels,
      );
      if (!mounted || generation != _generation) return;
      final bytes = pdf.bytes;
      setState(() {
        _pdf = pdf;
        _error = null;
        _build = (_) async => bytes;
      });
      widget.onGenerated?.call(pdf);
    } on InvoiceException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e);
      widget.onError?.call(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return widget.errorBuilder?.call(context, error) ??
          _DefaultError(error: error);
    }

    final pdf = _pdf;
    final build = _build;
    if (pdf == null || build == null) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    final showActions = widget.allowPrinting || widget.allowSharing;
    return PdfPreview(
      build: build,
      initialPageFormat: widget.theme.pageFormat,
      pdfFileName: pdf.fileName,
      useActions: showActions,
      allowPrinting: widget.allowPrinting,
      allowSharing: widget.allowSharing,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      maxPageWidth: widget.maxPageWidth,
      scrollViewDecoration: BoxDecoration(
        color: widget.backgroundColor ?? const Color(0xFFE2E8F0),
      ),
      loadingWidget: widget.loadingBuilder?.call(context),
    );
  }
}

/// Default error view: a title and the list of problems.
class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error});

  final InvoiceException error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;
    final lines = error is InvoiceValidationException
        ? [for (final issue in error.issues) '${issue.field}: ${issue.message}']
        : [error.message];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'The invoice could not be generated',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  line,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
