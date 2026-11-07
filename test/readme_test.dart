// Keeps README.md honest: every snippet there is repeated here, so it must
// compile and produce the numbers the README claims.
// If you change a README example, change it here too.

import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Quick start', () async {
    final printing = FakePrinting.install();
    final invoice = Invoice(
      invoiceNumber: 'INV-1001',
      issueDate: DateTime.now(),
      seller: const Business(name: 'ABC Technologies'),
      customer: const Customer(name: 'John Doe'),
      items: [
        InvoiceItem(
          name: 'Flutter App Development',
          quantity: 1,
          unitPrice: 500,
        ),
        InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100),
      ],
    );

    final pdf = await InvoiceGenerator.generate(invoice);
    await InvoiceGenerator.share(invoice);
    expect(pdf.totals.total, 700);
    expect(printing.callsTo(#sharePdf), hasLength(1));
  });

  test('Complete example', () async {
    final invoice = Invoice(
      invoiceNumber: 'INV-1001',
      issueDate: DateTime(2026, 11, 7),
      dueDate: DateTime(2026, 12, 7),
      // (README uses InvoiceLogo.asset('assets/logo.png'); the package's
      // own tests have no such asset, so the logo is left out here.)
      seller: const Business(
        name: 'ABC Technologies',
        email: 'hello@abc.com',
        phone: '+977 9800000000',
        address: 'Durbarmarg\nKathmandu, Nepal',
        website: 'abc.com',
        taxId: 'PAN 601234567',
      ),
      customer: const Customer(
        name: 'John Doe',
        companyName: 'Doe Retail Pvt. Ltd.',
        email: 'john@example.com',
        address: 'Lalitpur, Nepal',
      ),
      items: [
        InvoiceItem(
          name: 'Flutter App Development',
          description: 'iOS + Android app, 3 sprints',
          quantity: 1,
          unitPrice: 500,
        ),
        InvoiceItem(
          name: 'UI/UX Design',
          quantity: 2,
          unitPrice: 100,
          unit: 'screens',
        ),
        InvoiceItem(
          name: 'Consulting',
          quantity: 2.5,
          unitPrice: 80,
          unit: 'hrs',
        ),
      ],
      tax: const Tax(name: 'VAT', percentage: 13),
      discount: const Discount(type: DiscountType.percentage, value: 10),
      currency: Currency.usd,
      notes: 'Thank you for choosing ABC Technologies.',
      terms: 'Payment due within 30 days.',
      paymentInformation: const PaymentInformation(
        bankName: 'Nabil Bank',
        accountName: 'ABC Technologies',
        accountNumber: '0101 0172 0012',
        swiftBic: 'NARBNPKA',
      ),
      qrCode: const InvoiceQrCode.payment('https://pay.example.com/INV-1001'),
      details: const [InvoiceDetail(label: 'PO Number', value: 'PO-7781')],
      metadata: const {'orderId': '42'},
    );

    final pdf = await InvoiceGenerator.generate(
      invoice,
      template: InvoiceTemplate.modern,
      theme: InvoiceTheme(primaryColor: PdfColor.fromHex('#16A34A')),
    );
    expect(pdf.totals.total, 915.3);
  });

  test('Customization: the full theme and labels work', () async {
    final theme = InvoiceTheme(
      pageFormat: PdfPageFormat.letter,
      margin: 40,
      primaryColor: PdfColor.fromHex('#2563EB'),
      secondaryColor: PdfColors.blueGrey600,
      textColor: PdfColors.black,
      baseFontSize: 10,
      sectionSpacing: 14,
      borderRadius: 8,
      tableStyle: const InvoiceTableStyle(
        headerColor: PdfColors.blueGrey800,
        headerTextColor: PdfColors.white,
        stripeColor: PdfColors.grey100,
        showBorders: false,
        rowPadding: 6,
      ),
      showLogo: true,
      showPageNumbers: true,
      showContinuationHeader: true,
      footerText: 'ABC Technologies · abc.com',
      locale: 'en_US',
      dateFormat: 'dd/MM/yyyy',
    );
    const labels = InvoiceLabels(
      invoiceTitle: 'FACTURE',
      billTo: 'Facturer à',
      total: 'Total TTC',
      pageOf: 'Page {page} sur {pages}',
      thankYou: null,
    );
    for (final template in InvoiceTemplate.values) {
      final pdf = await InvoiceGenerator.generate(
        _sample(),
        template: template,
        theme: theme,
        labels: labels,
      );
      expect(pdf.pageCount, 1);
      expect(pdf.pageFormat, PdfPageFormat.letter);
    }
  });

  test('Tax, discounts and item overrides', () {
    final items = [
      InvoiceItem(
        name: 'Book',
        quantity: 1,
        unitPrice: 20,
        tax: const Tax(name: 'GST', percentage: 5),
      ),
      InvoiceItem(name: 'Export', quantity: 1, unitPrice: 50, taxes: const []),
      InvoiceItem(
        name: 'Design',
        quantity: 2,
        unitPrice: 100,
        discount: const Discount.percentage(10),
      ),
    ];
    final totals = InvoiceCalculator.calculate(
      _sample(items: items, discount: const Discount.fixed(5, label: 'Loyalty'))
          .copyWith(
        taxes: const [
          Tax(name: 'CGST', percentage: 9),
          Tax(name: 'SGST', percentage: 9),
        ],
      ),
    );
    expect(totals.lines[2].lineTotal, 180); // "line total 180.00"
    expect(totals.taxLines.map((t) => t.tax.name), ['GST', 'CGST', 'SGST']);
    expect(totals.lines[1].taxes, isEmpty); // tax-exempt
  });

  test('Currency examples', () {
    const kwd = Currency(code: 'KWD', symbol: 'KD', decimalDigits: 3);
    const sek = Currency(
      code: 'SEK',
      symbol: 'kr',
      symbolBeforeAmount: false,
      spaceBetweenSymbolAndAmount: true,
    );
    String money(Currency c, num v) => InvoiceFormatter(currency: c).money(v);
    expect(money(Currency.npr, 1234.5), 'Rs. 1,234.50');
    expect(money(Currency.usd, 1234.5), r'$1,234.50');
    expect(InvoiceFormatter(currency: sek).money(10), '10.00 kr');
    expect(InvoiceFormatter(currency: kwd).money(1.2345), 'KD1.235');
    expect(Currency.values, hasLength(8));
  });

  test('Calculations and rounding section', () {
    final totals = InvoiceCalculator.calculate(
      _sample(discount: const Discount.percentage(10)).copyWith(
        taxes: const [Tax(name: 'VAT', percentage: 13)],
      ),
    );
    expect(totals.subtotal, 700);
    expect(totals.discountAmount, 70);
    expect(totals.taxableAmount, 630);
    expect(totals.taxLines.single.amount, 81.9);
    expect(totals.taxAmount, 81.9);
    expect(totals.total, 711.9);
    expect(totals.totalInMinorUnits, 71190);
  });

  test('Errors section', () async {
    final invalid = _sample(
      items: [InvoiceItem(name: 'x', quantity: -1, unitPrice: 1)],
    );
    expect(
      InvoiceValidator.validate(invalid).single.toString(),
      'items[0].quantity: must not be negative (got -1)',
    );
    await expectLater(
      InvoiceGenerator.share(invalid),
      throwsA(isA<InvoiceValidationException>()),
    );
  });
}

Invoice _sample({List<InvoiceItem>? items, Discount? discount}) => Invoice(
      invoiceNumber: 'INV-1001',
      issueDate: DateTime(2026, 11, 7),
      seller: const Business(name: 'ABC Technologies'),
      customer: const Customer(name: 'John Doe'),
      items: items ??
          [
            InvoiceItem(
              name: 'Flutter App Development',
              quantity: 1,
              unitPrice: 500,
            ),
            InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100),
          ],
      discount: discount,
    );
