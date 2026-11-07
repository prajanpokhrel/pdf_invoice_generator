import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/sample_invoice.dart';

void main() {
  group('Invoice', () {
    test('quick-start invoice from the requirements can be created', () {
      final invoice = sampleInvoice();
      expect(invoice.invoiceNumber, 'INV-1001');
      expect(invoice.items, hasLength(2));
      expect(invoice.taxes, [const Tax(name: 'VAT', percentage: 13)]);
      expect(invoice.discount, const Discount.percentage(10));
      expect(invoice.currency, Currency.usd);
    });

    test('minimal invoice: sensible defaults', () {
      final invoice = Invoice(
        invoiceNumber: '1',
        issueDate: DateTime(2026),
        seller: const Business(name: 'S'),
        customer: const Customer(name: 'C'),
        items: [InvoiceItem(name: 'x', quantity: 1, unitPrice: 1)],
      );
      expect(invoice.currency, Currency.usd);
      expect(invoice.taxes, isEmpty);
      expect(invoice.discount, isNull);
      expect(invoice.dueDate, isNull);
      expect(invoice.details, isEmpty);
      expect(invoice.metadata, isEmpty);
    });

    test('supports multiple taxes', () {
      final invoice = Invoice(
        invoiceNumber: '1',
        issueDate: DateTime(2026),
        seller: const Business(name: 'S'),
        customer: const Customer(name: 'C'),
        items: const [],
        taxes: const [
          Tax(name: 'CGST', percentage: 9),
          Tax(name: 'SGST', percentage: 9),
        ],
      );
      expect(invoice.taxes.map((t) => t.name), ['CGST', 'SGST']);
    });

    test('passing both tax and taxes throws', () {
      expect(
        () => Invoice(
          invoiceNumber: '1',
          issueDate: DateTime(2026),
          seller: const Business(name: 'S'),
          customer: const Customer(name: 'C'),
          items: const [],
          tax: const Tax(name: 'A', percentage: 1),
          taxes: const [],
        ),
        throwsArgumentError,
      );
    });

    test('is immutable: items, details and metadata are copied', () {
      final items = [InvoiceItem(name: 'x', quantity: 1, unitPrice: 1)];
      final metadata = {'orderId': '42'};
      final invoice = Invoice(
        invoiceNumber: '1',
        issueDate: DateTime(2026),
        seller: const Business(name: 'S'),
        customer: const Customer(name: 'C'),
        items: items,
        metadata: metadata,
      );
      items.clear();
      metadata['orderId'] = 'changed';

      expect(invoice.items, hasLength(1));
      expect(invoice.metadata['orderId'], '42');
      expect(() => invoice.items.clear(), throwsUnsupportedError);
      expect(() => invoice.metadata['x'] = 'y', throwsUnsupportedError);
    });

    test('equality is by value', () {
      expect(sampleInvoice(), sampleInvoice());
      expect(sampleInvoice().hashCode, sampleInvoice().hashCode);
      expect(sampleInvoice(), isNot(sampleInvoice(currency: Currency.eur)));
    });

    test('metadata equality ignores key order', () {
      Invoice withMeta(Map<String, String> m) =>
          sampleInvoice().copyWith(metadata: m);
      final a = withMeta({'a': '1', 'b': '2'});
      final b = withMeta({'b': '2', 'a': '1'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('QR code is part of value equality', () {
      final withQr = sampleInvoice().copyWith(
        qrCode: const InvoiceQrCode.payment('https://pay.example.com/1'),
      );
      expect(withQr.qrCode!.type, InvoiceQrCodeType.payment);
      expect(withQr, isNot(sampleInvoice()));
      expect(
        withQr,
        sampleInvoice().copyWith(
          qrCode: const InvoiceQrCode.payment('https://pay.example.com/1'),
        ),
      );
    });

    test('copyWith keeps untouched fields', () {
      final original = sampleInvoice();
      final copy = original.copyWith(
        invoiceNumber: 'INV-2000',
        details: const [InvoiceDetail(label: 'PO', value: '7')],
      );
      expect(copy.invoiceNumber, 'INV-2000');
      expect(copy.details.single.value, '7');
      expect(copy.items, original.items);
      expect(copy.taxes, original.taxes);
      expect(copy.seller, original.seller);
    });
  });
}
