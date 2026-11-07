// Internal: the contract every built-in template implements.

import 'package:pdf/widgets.dart' as pw;

import '../render_context.dart';
import 'classic_template.dart';
import 'invoice_template.dart';
import 'minimal_template.dart';
import 'modern_template.dart';

/// Draws an invoice. Templates only decide the look: they read data and
/// totals from the [RenderContext] and never calculate anything.
abstract interface class TemplateRenderer {
  /// The flowing page content. MultiPage splits it across pages.
  List<pw.Widget> buildContent(RenderContext ctx);

  /// Header drawn at the top of every page.
  pw.Widget buildPageHeader(RenderContext ctx, pw.Context page);

  /// Footer drawn at the bottom of every page.
  pw.Widget buildPageFooter(RenderContext ctx, pw.Context page);
}

/// The renderer for [template].
TemplateRenderer rendererFor(InvoiceTemplate template) => switch (template.id) {
      TemplateId.classic => const ClassicTemplate(),
      TemplateId.modern => const ModernTemplate(),
      TemplateId.minimal => const MinimalTemplate(),
    };
