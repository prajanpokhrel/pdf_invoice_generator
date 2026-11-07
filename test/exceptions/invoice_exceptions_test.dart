import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceValidationException', () {
    test('lists every issue in the message', () {
      final e = InvoiceValidationException(const [
        InvoiceValidationIssue('invoiceNumber', 'must not be empty'),
        InvoiceValidationIssue('items[1].quantity', 'must not be negative'),
      ]);
      expect(e.issues, hasLength(2));
      expect(e.message, contains('2 problems'));
      expect(e.message, contains('items[1].quantity: must not be negative'));
      expect(e.toString(), startsWith('InvoiceValidationException'));
    });

    test('singular wording for one issue', () {
      final e = InvoiceValidationException(const [
        InvoiceValidationIssue('tax', 'bad'),
      ]);
      expect(e.message, contains('1 problem)'));
    });
  });

  test('all exceptions can be caught as InvoiceException', () {
    final errors = <InvoiceException>[
      InvoiceValidationException(const [InvoiceValidationIssue('a', 'b')]),
      const InvoiceImageException('Logo could not be decoded'),
      InvoiceGenerationException('boom', cause: StateError('x')),
    ];
    for (final e in errors) {
      expect(e, isA<Exception>());
      expect(e.message, isNotEmpty);
    }
    expect(errors.last.toString(), contains('cause: Bad state: x'));
  });
}
