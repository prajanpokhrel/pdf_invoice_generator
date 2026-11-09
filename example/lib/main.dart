// Invoice Studio - the demo app for flutter_invoice_generator.
//
// Everything invoice-related comes from the package:
//   * InvoiceDraft.toInvoice()  -> builds an Invoice (lib/src/invoice_draft.dart)
//   * InvoicePreview            -> live PDF preview   (lib/src/home_page.dart)
//   * pdf.share/print/save()    -> output actions     (lib/src/home_page.dart)
//
// The smallest possible use of the package is:
//
//   final pdf = await InvoiceGenerator.generate(invoice);

import 'package:flutter/material.dart';

import 'src/home_page.dart';

void main() => runApp(const InvoiceStudioApp());

class InvoiceStudioApp extends StatelessWidget {
  const InvoiceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
      colorSchemeSeed: const Color(0xFF2563EB),
      brightness: brightness,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      cardTheme: const CardThemeData(elevation: 0),
    );
    return MaterialApp(
      title: 'Invoice Studio',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const HomePage(),
    );
  }
}
