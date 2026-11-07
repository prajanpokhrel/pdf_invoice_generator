import 'dart:typed_data';

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Business', () {
    test('only name is required', () {
      const b = Business(name: 'ABC');
      expect(b.email, isNull);
      expect(b.logo, isNull);
    });

    test('supports all fields', () {
      final logo = InvoiceLogo.memory(Uint8List.fromList([1, 2, 3]));
      final b = Business(
        name: 'ABC',
        email: 'a@b.c',
        phone: '1',
        address: 'Street 1\nCity',
        website: 'abc.com',
        taxId: 'PAN-1',
        registrationNumber: 'REG-1',
        logo: logo,
      );
      expect(b.taxId, 'PAN-1');
      expect(b.registrationNumber, 'REG-1');
      expect(b.logo, logo);
    });

    test('equality and copyWith', () {
      const b = Business(name: 'ABC', email: 'a@b.c');
      expect(b, const Business(name: 'ABC', email: 'a@b.c'));
      expect(b.copyWith(name: 'XYZ').email, 'a@b.c');
      expect(b.copyWith(name: 'XYZ'), isNot(b));
    });
  });

  group('Customer', () {
    test('supports all fields', () {
      const c = Customer(
        name: 'John',
        companyName: 'Acme',
        email: 'j@acme.com',
        phone: '2',
        address: 'Lalitpur',
        taxId: 'VAT-9',
      );
      expect(c.companyName, 'Acme');
      expect(c, c.copyWith());
    });
  });

  group('PaymentInformation', () {
    test('all fields optional', () {
      const p = PaymentInformation();
      expect(p.isEmpty, isTrue);
    });

    test('works without IBAN', () {
      const p = PaymentInformation(
        bankName: 'Nabil Bank',
        accountNumber: '0123',
        routingNumber: 'NARBNPKA',
      );
      expect(p.isEmpty, isFalse);
      expect(p.iban, isNull);
    });
  });

  group('InvoiceLogo', () {
    test('asset and network logos compare by value', () {
      expect(
        const InvoiceLogo.asset('assets/logo.png'),
        const InvoiceLogo.asset('assets/logo.png'),
      );
      expect(
        const InvoiceLogo.network('https://x.com/a.png'),
        isNot(const InvoiceLogo.asset('https://x.com/a.png')),
      );
    });

    test('memory logos compare by buffer identity', () {
      final bytes = Uint8List.fromList([1, 2]);
      expect(InvoiceLogo.memory(bytes), InvoiceLogo.memory(bytes));
      expect(
        InvoiceLogo.memory(bytes),
        isNot(InvoiceLogo.memory(Uint8List.fromList([1, 2]))),
      );
    });
  });
}
