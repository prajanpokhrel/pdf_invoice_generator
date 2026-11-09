import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';

import 'editor_panel.dart';
import 'invoice_draft.dart';

/// Editor + live preview. Side by side on wide screens, tabs on phones.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _draft = InvoiceDraft();

  /// What the preview shows. Updated shortly after the user stops typing,
  /// so the PDF is not rebuilt on every keystroke.
  late Invoice _previewInvoice = _draft.toInvoice();
  late InvoiceTheme _previewTheme = _draft.theme;
  late InvoiceTemplate _previewTemplate = _draft.template;
  Timer? _debounce;

  /// The PDF currently on screen, reused by Share/Print/Save.
  InvoicePdf? _pdf;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _draft.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _draft
      ..removeListener(_onDraftChanged)
      ..dispose();
    super.dispose();
  }

  void _onDraftChanged() {
    setState(() {}); // rebuild the form (item count, validation banner...)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _previewInvoice = _draft.toInvoice();
        _previewTheme = _draft.theme;
        _previewTemplate = _draft.template;
      });
    });
  }

  Future<void> _run(
    String done,
    Future<String?> Function(InvoicePdf) action,
  ) async {
    final pdf = _pdf;
    if (pdf == null || _busy) return;
    // Read everything that needs `context` before the first `await`.
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    setState(() => _busy = true);
    try {
      final message = await action(pdf);
      messenger.showSnackBar(SnackBar(content: Text(message ?? done)));
    } on InvoiceException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: errorColor),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _share(Rect? origin) => _run('Shared', (pdf) async {
    final ok = await pdf.share(
      subject: 'Invoice ${_previewInvoice.invoiceNumber}',
      sharePositionOrigin: origin,
    );
    return ok ? null : 'Sharing cancelled';
  });

  void _print() => _run('Sent to printer', (pdf) async {
    final ok = await pdf.print();
    return ok ? null : 'Printing cancelled';
  });

  void _save() => _run('Saved', (pdf) async {
    final result = await pdf.save();
    return result.isDownload
        ? 'Downloaded ${result.fileName}'
        : 'Saved to ${result.path}';
  });

  @override
  Widget build(BuildContext context) {
    final issues = InvoiceValidator.validate(_draft.toInvoice());
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final editor = Column(
          children: [
            if (issues.isNotEmpty) _IssuesBanner(issues: issues),
            Expanded(child: EditorPanel(draft: _draft)),
          ],
        );
        final preview = _PreviewPane(
          invoice: _previewInvoice,
          theme: _previewTheme,
          template: _previewTemplate,
          onGenerated: (pdf) => setState(() => _pdf = pdf),
          onError: (_) => setState(() => _pdf = null),
        );
        final actions = _Actions(
          enabled: _pdf != null && !_busy,
          onShare: _share,
          onPrint: _print,
          onSave: _save,
        );

        if (wide) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Invoice Studio'),
              actions: [actions, const SizedBox(width: 12)],
            ),
            body: Row(
              children: [
                SizedBox(width: 460, child: editor),
                const VerticalDivider(width: 1),
                Expanded(child: preview),
              ],
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Invoice Studio'),
              actions: [actions],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.edit_outlined), text: 'Edit'),
                  Tab(
                    icon: Icon(Icons.picture_as_pdf_outlined),
                    text: 'Preview',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              // Keep the editor's text fields alive when switching tabs.
              children: [
                _KeepAlive(child: editor),
                preview,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.invoice,
    required this.theme,
    required this.template,
    required this.onGenerated,
    required this.onError,
  });

  final Invoice invoice;
  final InvoiceTheme theme;
  final InvoiceTemplate template;
  final ValueChanged<InvoicePdf> onGenerated;
  final ValueChanged<InvoiceException> onError;

  @override
  Widget build(BuildContext context) {
    return InvoicePreview(
      invoice: invoice,
      theme: theme,
      template: template,
      maxPageWidth: 720,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      onGenerated: onGenerated,
      onError: onError,
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note, size: 48),
              const SizedBox(height: 12),
              Text(
                'Fix the highlighted problems to see the preview',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.enabled,
    required this.onShare,
    required this.onPrint,
    required this.onSave,
  });

  final bool enabled;
  final void Function(Rect? origin) onShare;
  final VoidCallback onPrint;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          // The button's position is needed for the iPad share popover.
          builder: (buttonContext) => IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: enabled
                ? () {
                    final box = buttonContext.findRenderObject() as RenderBox?;
                    onShare(
                      box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    );
                  }
                : null,
          ),
        ),
        IconButton(
          tooltip: 'Print',
          icon: const Icon(Icons.print_outlined),
          onPressed: enabled ? onPrint : null,
        ),
        IconButton(
          tooltip: 'Save',
          icon: const Icon(Icons.download_outlined),
          onPressed: enabled ? onSave : null,
        ),
      ],
    );
  }
}

class _IssuesBanner extends StatelessWidget {
  const _IssuesBanner({required this.issues});

  final List<InvoiceValidationIssue> issues;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                issues.map((i) => '${i.field}: ${i.message}').join('\n'),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
