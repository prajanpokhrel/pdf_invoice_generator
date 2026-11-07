import 'package:flutter_invoice_generator/flutter_invoice_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('InvoiceFormatter.money', () {
    test('symbol before, grouping and fixed decimals', () {
      final f = InvoiceFormatter(currency: Currency.usd);
      expect(f.money(0), r'$0.00');
      expect(f.money(1234.5), r'$1,234.50');
      expect(f.money(1129999988700), r'$1,129,999,988,700.00');
    });

    test('negative amounts put the sign first', () {
      expect(InvoiceFormatter(currency: Currency.usd).money(-70), r'-$70.00');
    });

    test('space between symbol and amount (NPR)', () {
      expect(
        InvoiceFormatter(currency: Currency.npr).money(711.9),
        'Rs. 711.90',
      );
    });

    test('zero-decimal currency (JPY)', () {
      expect(InvoiceFormatter(currency: Currency.jpy).money(1101), '¥1,101');
    });

    test('symbol after the amount', () {
      const sek = Currency(
        code: 'SEK',
        symbol: 'kr',
        symbolBeforeAmount: false,
        spaceBetweenSymbolAndAmount: true,
      );
      expect(InvoiceFormatter(currency: sek).money(10), '10.00 kr');
    });

    test('locale changes separators', () {
      final f = InvoiceFormatter(currency: Currency.eur, locale: 'de_DE');
      expect(f.money(1234.5), '€1.234,50');
    });
  });

  test('quantity keeps meaningful decimals only', () {
    final f = InvoiceFormatter(currency: Currency.usd);
    expect(f.quantity(1), '1');
    expect(f.quantity(2.5), '2.5');
    expect(f.quantity(0.75), '0.75');
    expect(f.quantity(1000), '1,000');
  });

  test('percent', () {
    final f = InvoiceFormatter(currency: Currency.usd);
    expect(f.percent(13), '13%');
    expect(f.percent(2.5), '2.5%');
  });

  test('dates', () {
    final d = DateTime(2026, 11, 7);
    expect(InvoiceFormatter(currency: Currency.usd).date(d), 'Nov 7, 2026');
    expect(
      InvoiceFormatter(currency: Currency.usd, datePattern: 'dd/MM/yyyy')
          .date(d),
      '07/11/2026',
    );
  });

  group('locales', () {
    test('unknown locale gives a helpful error', () {
      expect(
        () => InvoiceFormatter(currency: Currency.usd, locale: 'xx_YY'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('not supported'),
          ),
        ),
      );
    });

    test('money works without date data; dates explain what to call', () {
      final f = InvoiceFormatter(currency: Currency.eur, locale: 'it_IT');
      expect(f.money(1234.5), '€1.234,50');
      expect(
        () => f.date(DateTime(2026, 11, 7)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('initializeDateFormatting("it_IT")'),
          ),
        ),
      );
    });

    test('dates work after initializeDateFormatting', () async {
      await initializeDateFormatting('de_DE');
      final f = InvoiceFormatter(currency: Currency.eur, locale: 'de_DE');
      expect(f.date(DateTime(2026, 11, 7)), 'Nov. 7, 2026');
    });
  });
}
