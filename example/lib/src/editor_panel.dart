import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';

import 'invoice_draft.dart';

/// Accent colours offered in the style section.
final accentColors = [
  PdfColor.fromHex('#2563EB'),
  PdfColor.fromHex('#16A34A'),
  PdfColor.fromHex('#9333EA'),
  PdfColor.fromHex('#DC2626'),
  PdfColor.fromHex('#0F172A'),
];

Color toFlutterColor(PdfColor c) => Color(c.toInt());

/// The form on the left (wide screens) or in the "Edit" tab (phones).
class EditorPanel extends StatelessWidget {
  const EditorPanel({required this.draft, super.key});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StyleSection(draft: draft),
        _BusinessSection(draft: draft),
        _CustomerSection(draft: draft),
        _ItemsSection(draft: draft),
        _PricingSection(draft: draft),
        _ExtrasSection(draft: draft),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A text field that reports every change.
class TextInput extends StatelessWidget {
  const TextInput({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }
}

/// A decimal number field. Invalid text counts as 0, so the package's
/// validator (not the form) decides what is allowed.
class NumberInput extends StatelessWidget {
  const NumberInput({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.suffix,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;

  static String format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: format(value),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
        ],
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        onChanged: (text) =>
            onChanged(double.tryParse(text.replaceAll(',', '')) ?? 0),
      ),
    );
  }
}

Widget _row(List<Widget> children) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _StyleSection extends StatelessWidget {
  const _StyleSection({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Template & style',
      icon: Icons.palette_outlined,
      children: [
        SegmentedButton<InvoiceTemplate>(
          segments: [
            for (final t in InvoiceTemplate.values)
              ButtonSegment(
                value: t,
                label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
              ),
          ],
          selected: {draft.template},
          onSelectionChanged: (s) =>
              draft.update(() => draft.template = s.first),
        ),
        const SizedBox(height: 16),
        Text('Accent colour', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            for (final color in accentColors)
              _Swatch(
                color: toFlutterColor(color),
                selected: color == draft.primaryColor,
                onTap: () => draft.update(() => draft.primaryColor = color),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _row([
          DropdownButtonFormField<Currency>(
            isExpanded: true,
            initialValue: draft.currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: [
              for (final c in Currency.values)
                DropdownMenuItem(
                    value: c, child: Text('${c.code}  ${c.symbol}')),
            ],
            onChanged: (c) => draft.update(() => draft.currency = c!),
          ),
          DropdownButtonFormField<PdfPageFormat>(
            isExpanded: true,
            initialValue: draft.pageFormat,
            decoration: const InputDecoration(labelText: 'Paper'),
            items: const [
              DropdownMenuItem(value: PdfPageFormat.a4, child: Text('A4')),
              DropdownMenuItem(
                  value: PdfPageFormat.letter, child: Text('Letter')),
            ],
            onChanged: (f) => draft.update(() => draft.pageFormat = f!),
          ),
        ]),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}

class _BusinessSection extends StatelessWidget {
  const _BusinessSection({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Your business',
      icon: Icons.storefront_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Logo'),
          Switch(
            value: draft.showLogo,
            onChanged: (v) => draft.update(() => draft.showLogo = v),
          ),
        ],
      ),
      children: [
        TextInput(
          label: 'Business name',
          value: draft.businessName,
          onChanged: (v) => draft.update(() => draft.businessName = v),
        ),
        _row([
          TextInput(
            label: 'Email',
            value: draft.businessEmail,
            onChanged: (v) => draft.update(() => draft.businessEmail = v),
          ),
          TextInput(
            label: 'Phone',
            value: draft.businessPhone,
            onChanged: (v) => draft.update(() => draft.businessPhone = v),
          ),
        ]),
        TextInput(
          label: 'Address',
          value: draft.businessAddress,
          onChanged: (v) => draft.update(() => draft.businessAddress = v),
        ),
        TextInput(
          label: 'Tax ID',
          value: draft.businessTaxId,
          onChanged: (v) => draft.update(() => draft.businessTaxId = v),
        ),
      ],
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Customer',
      icon: Icons.person_outline,
      children: [
        _row([
          TextInput(
            label: 'Name',
            value: draft.customerName,
            onChanged: (v) => draft.update(() => draft.customerName = v),
          ),
          TextInput(
            label: 'Company',
            value: draft.customerCompany,
            onChanged: (v) => draft.update(() => draft.customerCompany = v),
          ),
        ]),
        TextInput(
          label: 'Email',
          value: draft.customerEmail,
          onChanged: (v) => draft.update(() => draft.customerEmail = v),
        ),
        TextInput(
          label: 'Address',
          value: draft.customerAddress,
          onChanged: (v) => draft.update(() => draft.customerAddress = v),
        ),
      ],
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = InvoiceFormatter(currency: draft.currency);
    return SectionCard(
      title: 'Items (${draft.items.length})',
      icon: Icons.list_alt_outlined,
      trailing: FilledButton.tonalIcon(
        onPressed: draft.addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      children: [
        if (draft.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No items yet. An invoice needs at least one.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        for (final item in draft.items)
          Container(
            // The key keeps each row's text fields attached to the right
            // item when another item is removed.
            key: ValueKey(item.id),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextInput(
                        label: 'Item',
                        value: item.name,
                        onChanged: (v) => draft.update(() => item.name = v),
                      ),
                      TextInput(
                        label: 'Description (optional)',
                        value: item.description,
                        onChanged: (v) =>
                            draft.update(() => item.description = v),
                      ),
                      _row([
                        NumberInput(
                          label: 'Qty',
                          value: item.quantity,
                          onChanged: (v) =>
                              draft.update(() => item.quantity = v),
                        ),
                        TextInput(
                          label: 'Unit',
                          value: item.unit,
                          onChanged: (v) => draft.update(() => item.unit = v),
                        ),
                        NumberInput(
                          label: 'Price',
                          value: item.unitPrice,
                          suffix: draft.currency.code,
                          onChanged: (v) =>
                              draft.update(() => item.unitPrice = v),
                        ),
                      ]),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Remove item',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => draft.removeItem(item),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Text(
                        formatter.money(item.quantity * item.unitPrice),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Discount & tax',
      icon: Icons.percent,
      children: [
        SegmentedButton<DiscountMode>(
          segments: const [
            ButtonSegment(value: DiscountMode.none, label: Text('No discount')),
            ButtonSegment(value: DiscountMode.percentage, label: Text('%')),
            ButtonSegment(value: DiscountMode.fixed, label: Text('Fixed')),
          ],
          selected: {draft.discountMode},
          onSelectionChanged: (s) =>
              draft.update(() => draft.discountMode = s.first),
        ),
        const SizedBox(height: 12),
        if (draft.discountMode != DiscountMode.none)
          NumberInput(
            key: ValueKey(draft.discountMode),
            label: 'Discount',
            value: draft.discountValue,
            suffix: draft.discountMode == DiscountMode.percentage
                ? '%'
                : draft.currency.code,
            onChanged: (v) => draft.update(() => draft.discountValue = v),
          ),
        _row([
          TextInput(
            label: 'Tax name',
            value: draft.taxName,
            onChanged: (v) => draft.update(() => draft.taxName = v),
          ),
          NumberInput(
            label: 'Tax rate (0 = none)',
            value: draft.taxPercentage,
            suffix: '%',
            onChanged: (v) => draft.update(() => draft.taxPercentage = v),
          ),
        ]),
      ],
    );
  }
}

class _ExtrasSection extends StatelessWidget {
  const _ExtrasSection({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Invoice details & payment',
      icon: Icons.receipt_long_outlined,
      children: [
        _row([
          TextInput(
            label: 'Invoice number',
            value: draft.invoiceNumber,
            onChanged: (v) => draft.update(() => draft.invoiceNumber = v),
          ),
          NumberInput(
            label: 'Due in',
            value: draft.dueInDays.toDouble(),
            suffix: 'days',
            onChanged: (v) => draft.update(() => draft.dueInDays = v.round()),
          ),
        ]),
        _row([
          TextInput(
            label: 'Bank',
            value: draft.bankName,
            onChanged: (v) => draft.update(() => draft.bankName = v),
          ),
          TextInput(
            label: 'Account number',
            value: draft.accountNumber,
            onChanged: (v) => draft.update(() => draft.accountNumber = v),
          ),
        ]),
        TextInput(
          label: 'Notes',
          value: draft.notes,
          maxLines: 3,
          onChanged: (v) => draft.update(() => draft.notes = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Payment QR code'),
          subtitle: const Text('Links to a payment page'),
          value: draft.includeQrCode,
          onChanged: (v) => draft.update(() => draft.includeQrCode = v),
        ),
      ],
    );
  }
}
