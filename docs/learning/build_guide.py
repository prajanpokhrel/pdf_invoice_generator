"""Builds the learning guide PDF for flutter_invoice_generator.

Run:  python3 docs/learning/build_guide.py
Output: docs/learning/flutter_invoice_generator_guide.pdf

One chapter is added per development phase.
"""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

OUT = Path(__file__).with_name("flutter_invoice_generator_guide.pdf")

BLUE = colors.HexColor("#2563EB")
DARK = colors.HexColor("#0F172A")
MUTED = colors.HexColor("#475569")
LIGHT = colors.HexColor("#EFF6FF")
CODE_BG = colors.HexColor("#F1F5F9")
GREEN_BG = colors.HexColor("#ECFDF5")
GREEN = colors.HexColor("#047857")
AMBER_BG = colors.HexColor("#FFFBEB")
AMBER = colors.HexColor("#B45309")

base = getSampleStyleSheet()
S = {
    "title": ParagraphStyle("t", parent=base["Title"], fontSize=26, leading=32,
                            textColor=DARK, alignment=TA_CENTER),
    "subtitle": ParagraphStyle("st", parent=base["Normal"], fontSize=13,
                               leading=18, textColor=MUTED, alignment=TA_CENTER),
    "h1": ParagraphStyle("h1", parent=base["Heading1"], fontSize=20, leading=26,
                         textColor=BLUE, spaceBefore=6, spaceAfter=10),
    "h2": ParagraphStyle("h2", parent=base["Heading2"], fontSize=14, leading=19,
                         textColor=DARK, spaceBefore=12, spaceAfter=6),
    "body": ParagraphStyle("b", parent=base["Normal"], fontSize=10.5,
                           leading=15.5, textColor=DARK, spaceAfter=6),
    "bullet": ParagraphStyle("bl", parent=base["Normal"], fontSize=10.5,
                             leading=15, textColor=DARK, leftIndent=14,
                             bulletIndent=4, spaceAfter=2),
    "code": ParagraphStyle("c", fontName="Courier", fontSize=8.6, leading=11.2,
                           textColor=DARK),
    "cell": ParagraphStyle("cell", parent=base["Normal"], fontSize=9.4,
                           leading=12.5, textColor=DARK),
    "cellb": ParagraphStyle("cellb", parent=base["Normal"], fontSize=9.4,
                            leading=12.5, textColor=colors.white,
                            fontName="Helvetica-Bold"),
    "box": ParagraphStyle("box", parent=base["Normal"], fontSize=10.2,
                          leading=14.5, textColor=DARK),
}

story = []


def h1(t):
    story.append(Paragraph(t, S["h1"]))


def h2(t):
    story.append(Paragraph(t, S["h2"]))


def p(t):
    story.append(Paragraph(t, S["body"]))


def bullets(items):
    for it in items:
        story.append(Paragraph(it, S["bullet"], bulletText="•"))
    story.append(Spacer(1, 4))


def code(text):
    pre = Preformatted(text.strip("\n"), S["code"])
    t = Table([[pre]], colWidths=[170 * mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CODE_BG),
        ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(t)
    story.append(Spacer(1, 8))


def callout(title, text, bg=LIGHT, fg=BLUE):
    content = [Paragraph(f"<b><font color='{fg.hexval()}'>{title}</font></b>",
                         S["box"]),
               Spacer(1, 2), Paragraph(text, S["box"])]
    t = Table([[content]], colWidths=[170 * mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("LINEBEFORE", (0, 0), (0, -1), 3, fg),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    story.append(KeepTogether([t, Spacer(1, 8)]))


def simple(text):
    callout("In simple words", text, GREEN_BG, GREEN)


def decision(text):
    callout("Decision for you to approve", text, AMBER_BG, AMBER)


def table(header, rows, widths):
    data = [[Paragraph(h, S["cellb"]) for h in header]]
    data += [[Paragraph(str(c), S["cell"]) for c in r] for r in rows]
    t = Table(data, colWidths=[w * mm for w in widths], repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), BLUE),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, CODE_BG]),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    story.append(Spacer(1, 10))


def flow(steps):
    """Vertical box diagram: list of (title, subtitle)."""
    rows = []
    for i, (title, sub) in enumerate(steps):
        rows.append([Paragraph(f"<b>{title}</b><br/><font size=8.5 color='#475569'>"
                               f"{sub}</font>", S["cell"])])
        if i < len(steps) - 1:
            rows.append([Paragraph("<font color='#2563EB'><b>|<br/>v</b></font>",
                                   ParagraphStyle("arr", parent=S["cell"],
                                                  alignment=TA_CENTER,
                                                  leading=8))])
    t = Table(rows, colWidths=[110 * mm])
    style = [("ALIGN", (0, 0), (-1, -1), "CENTER")]
    for r in range(0, len(rows), 2):
        style += [("BACKGROUND", (0, r), (0, r), LIGHT),
                  ("BOX", (0, r), (0, r), 0.8, BLUE),
                  ("TOPPADDING", (0, r), (0, r), 6),
                  ("BOTTOMPADDING", (0, r), (0, r), 6),
                  ("LEFTPADDING", (0, r), (0, r), 8)]
    for r in range(1, len(rows), 2):
        style += [("TOPPADDING", (0, r), (0, r), 1),
                  ("BOTTOMPADDING", (0, r), (0, r), 1)]
    t.setStyle(TableStyle(style))
    story.append(t)
    story.append(Spacer(1, 10))


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(20 * mm, 12 * mm, "flutter_invoice_generator - Learning Guide")
    canvas.drawRightString(190 * mm, 12 * mm, f"Page {doc.page}")
    canvas.restoreState()


# --------------------------------------------------------------------------
# Cover
# --------------------------------------------------------------------------
story += [Spacer(1, 60 * mm),
          Paragraph("flutter_invoice_generator", S["title"]),
          Spacer(1, 6),
          Paragraph("Learning Guide - how the package is designed and built,"
                    " phase by phase, in simple language", S["subtitle"]),
          Spacer(1, 18),
          Paragraph("Chapter 1: Phase 1 - Architecture Plan", S["subtitle"]),
          Paragraph("Chapter 2: Phase 2 - Package Skeleton and Models",
                    S["subtitle"]),
          Spacer(1, 58 * mm),
          Paragraph("Chapter 3: Phase 3 - Calculation Engine", S["subtitle"]),
          Paragraph("Status: Phase 3 complete.", S["subtitle"]),
          PageBreak()]

# --------------------------------------------------------------------------
# 1. What are we building
# --------------------------------------------------------------------------
h1("1. What are we building?")
p("We are building a <b>Flutter package</b> (also called a library or SDK). "
  "A package is not an app. Nobody 'opens' it on their phone. Instead, other "
  "Flutter developers add it to their own apps with one line in "
  "<font face='Courier'>pubspec.yaml</font>, and then they get ready-made "
  "classes and functions they can call.")
p("Our package gives them one job, done very well: <b>turn invoice data into "
  "a professional PDF</b>, then let them preview, save, share or print it.")
simple("Think of the package as a machine. Developers put in data (who sells, "
       "who buys, what items, which tax) and the machine gives back a "
       "finished PDF invoice. They never need to know how the machine works "
       "inside.")

h2("The developer experience we want")
code("""
final invoice = Invoice(
  invoiceNumber: 'INV-1001',
  issueDate: DateTime.now(),
  dueDate: DateTime.now().add(const Duration(days: 30)),
  seller: Business(name: 'ABC Technologies', email: 'hello@abc.com'),
  customer: Customer(name: 'John Doe', email: 'john@example.com'),
  items: [
    InvoiceItem(name: 'Flutter App Development', quantity: 1, unitPrice: 500),
    InvoiceItem(name: 'UI/UX Design', quantity: 2, unitPrice: 100),
  ],
  tax: Tax(name: 'VAT', percentage: 13),
  discount: Discount.percentage(10),
  currency: Currency.usd,
);

final pdf = await InvoiceGenerator.generate(invoice);  // build the PDF
await InvoiceGenerator.share(invoice);                 // share sheet
await InvoiceGenerator.print(invoice);                 // print dialog
await InvoiceGenerator.save(invoice);                  // save to a file
""")

h2("Important: your current folder")
p("Right now <font face='Courier'>pdf_invoice/</font> was created with "
  "<font face='Courier'>flutter create</font> as an <b>app</b>. It has "
  "<font face='Courier'>android/ ios/ web/ macos/ windows/ linux/</font> "
  "folders and a <font face='Courier'>main.dart</font>. A package does not "
  "need those at the root. In Phase 2 we convert it:")
bullets([
    "Remove the platform folders and <font face='Courier'>lib/main.dart</font> "
    "from the root (they are only generated boilerplate, no code of yours).",
    "Rename the package to <font face='Courier'>flutter_invoice_generator</font> "
    "in <font face='Courier'>pubspec.yaml</font>.",
    "Create a separate demo app inside <font face='Courier'>example/</font>. "
    "That demo app is where the platform folders belong.",
])

story.append(PageBreak())

# --------------------------------------------------------------------------
# 2. Architecture in layers
# --------------------------------------------------------------------------
h1("2. The big picture: layers")
p("The most important idea in this package is <b>separation</b>. Each layer "
  "does one job and only talks to the layer next to it. This keeps the code "
  "easy to test and easy to change later.")
flow([
    ("1. Models (data)", "Invoice, Business, Customer, InvoiceItem, Tax, Discount,"
     " Currency... Plain Dart objects. No Flutter, no PDF."),
    ("2. Validation", "Checks the data: no negative price, tax between 0-100%,"
     " at least one item... Collects ALL problems at once."),
    ("3. Calculation engine", "InvoiceCalculator turns the data into numbers:"
     " subtotal, discount, taxable amount, tax, total."),
    ("4. Formatting", "Turns numbers and dates into text: 711.9 -> '$711.90',"
     " 2026-11-07 -> 'Nov 7, 2026'."),
    ("5. PDF renderer + templates", "Draws the pages using the 'pdf' package."
     " Templates only decide the LOOK, never the math."),
    ("6. Output (Flutter layer)", "Preview widget, save, share, print -"
     " uses the 'printing' plugin."),
])
simple("It is like a restaurant. Models are the ingredients, validation is "
       "checking the ingredients are fresh, the calculator is the recipe, "
       "templates are how the plate is decorated, and output is the waiter "
       "delivering the plate. The decorator never changes the recipe.")

h2("Why this matters")
bullets([
    "<b>Testing:</b> we can test the money math with no PDF at all - fast and exact.",
    "<b>Templates:</b> Classic, Modern and Minimal share the same engine. "
    "Only the drawing code differs, so a bug fixed in the math is fixed for all.",
    "<b>Server use:</b> layers 1-5 do not need Flutter UI, so the same code "
    "could later generate invoices on a Dart server.",
])

story.append(PageBreak())

# --------------------------------------------------------------------------
# 3. Folder structure
# --------------------------------------------------------------------------
h1("3. Folder structure")
p("This follows the structure you asked for, with a few small additions "
  "(marked NEW) that I explain below.")
code("""
flutter_invoice_generator/
|-- lib/
|   |-- flutter_invoice_generator.dart   <- the ONLY public entry file
|   `-- src/                             <- private implementation
|       |-- models/
|       |   |-- invoice.dart
|       |   |-- invoice_item.dart
|       |   |-- business.dart
|       |   |-- customer.dart
|       |   |-- tax.dart
|       |   |-- discount.dart
|       |   |-- currency.dart
|       |   |-- payment_information.dart
|       |   `-- invoice_logo.dart          NEW: bytes / asset / network logo
|       |-- calculation/
|       |   |-- invoice_calculator.dart
|       |   |-- invoice_totals.dart
|       |   `-- money.dart                 NEW (internal): exact money math
|       |-- validation/                    NEW
|       |   `-- invoice_validator.dart
|       |-- formatting/                    NEW
|       |   `-- invoice_formatter.dart     dates + money text
|       |-- pdf/
|       |   |-- invoice_generator.dart     public facade (generate/save/...)
|       |   |-- invoice_pdf.dart           the result object
|       |   |-- invoice_pdf_builder.dart   internal engine (MultiPage)
|       |   |-- invoice_theme.dart         colors, fonts, sizes
|       |   |-- invoice_labels.dart        NEW: 'INVOICE', 'Bill To'... (translatable)
|       |   |-- sections/                  NEW: shared building blocks
|       |   |   (header, parties, items_table, summary, footer)
|       |   `-- templates/
|       |       |-- invoice_template.dart
|       |       |-- classic_template.dart
|       |       |-- modern_template.dart
|       |       `-- minimal_template.dart
|       |-- preview/
|       |   `-- invoice_preview.dart
|       |-- output/                        NEW: save / share / print
|       |   `-- invoice_output.dart
|       `-- exceptions/
|           `-- invoice_exceptions.dart
|-- assets/fonts/                         NEW: bundled Unicode font
|-- example/                             demo Flutter app
|-- test/  (models/ calculation/ validation/ pdf/)
|-- docs/learning/                       this guide (not published)
|-- README.md  CHANGELOG.md  LICENSE
|-- pubspec.yaml  analysis_options.yaml
""")
h2("Why lib/src?")
p("In Dart, anything under <font face='Courier'>lib/src/</font> is "
  "considered private. Developers only import "
  "<font face='Courier'>package:flutter_invoice_generator/flutter_invoice_generator.dart</font>, "
  "and that file decides exactly what is visible using "
  "<font face='Courier'>export</font>. If a class is not exported, we can "
  "rename or rewrite it later without breaking anyone's app.")
simple("lib/src is the kitchen. The export file is the menu. Customers only "
       "order from the menu, so we can reorganise the kitchen any time.")


# --------------------------------------------------------------------------
# 4. Dependencies
# --------------------------------------------------------------------------
h1("4. Dependencies (and why each one)")
p("I checked pub.dev on 7 Nov 2026 for the current versions. Fewer "
  "dependencies means fewer version conflicts for the people who install us.")
table(["Package", "Version", "Why we need it", "Could we avoid it?"], [
    ["pdf", "^3.13.1", "Builds the PDF: pages, tables, text, images, "
     "MultiPage for long invoices. Also includes 'barcode', so QR codes are free.",
     "No - this is the core."],
    ["printing", "^5.15.1", "Print dialog, share sheet, PDF preview widget, "
     "loading network images. Supports Android, iOS, macOS, Windows, Linux, Web.",
     "No - writing native print code for 6 platforms is huge."],
    ["intl", ">=0.19.0 <0.21.0", "Date formats ('07/11/2026') and number "
     "grouping ('1,234.50') for any locale.",
     "Possible, but locale rules are hard. A WIDE range is used because "
     "Flutter's own localization pins one intl version."],
    ["path_provider", "^2.x (to confirm)", "Only for save(): finds the app "
     "documents folder on each platform.",
     "Yes - see decision below."],
    ["meta", "(already via Flutter)", "@immutable annotations.", "Free."],
], [28, 30, 62, 50])
decision("<b>save():</b> Option A (recommended): use path_provider so "
         "<font face='Courier'>save(invoice)</font> works with no arguments and "
         "returns the saved file path. Option B: no extra dependency, but the "
         "developer must pass a directory: <font face='Courier'>save(invoice, "
         "directory: dir)</font>. On Web, save() downloads the file through "
         "the browser either way.")

h2("A hidden problem: currency symbols and fonts")
p("PDFs need a font file that contains every character we print. The "
  "built-in PDF font (Helvetica) does <b>not</b> contain the Indian Rupee "
  "sign or many non-English letters. A Nepali shop printing a customer "
  "name in Devanagari would get empty boxes.")
decision("Bundle one open-licence font (Noto Sans, regular + bold, about "
         "1 MB) as the default, which includes symbols like the Rupee sign. "
         "Developers can still pass any font through InvoiceTheme. "
         "This keeps generation <b>fully offline</b> (no downloading Google "
         "Fonts at runtime).")

story.append(PageBreak())

# --------------------------------------------------------------------------
# 5. Models
# --------------------------------------------------------------------------
h1("5. The models (the data)")
p("All models are <b>immutable</b>: once created they never change. To "
  "'edit', you call <font face='Courier'>copyWith(...)</font> which returns a "
  "new copy. This prevents bugs where one screen changes an invoice that "
  "another screen is still printing.")
code("""
Invoice
 |-- invoiceNumber, issueDate, dueDate
 |-- seller   : Business   (name, email, phone, address, website,
 |                          taxId, registrationNumber, logo)
 |-- customer : Customer   (name, companyName, email, phone, address, taxId)
 |-- items    : List<InvoiceItem>
 |                (name, description, quantity (double), unitPrice,
 |                 sku, unit, tax?, discount?)
 |-- currency : Currency    (code, symbol, decimalDigits, symbolOnLeft)
 |-- taxes    : List<Tax>   (name, percentage)  <- 'tax:' shortcut for one
 |-- discount : Discount?   (percentage or fixed)
 |-- paymentInformation : PaymentInformation? (all fields optional)
 |-- notes, terms
 |-- details  : List<InvoiceDetail>  (extra rows shown, e.g. 'PO Number')
 `-- metadata : Map<String, String>  (your own data, never printed)
""")
h2("Design choices explained")
bullets([
    "<b>Quantity is a double</b>, so 2.5 hours or 0.75 kg work.",
    "<b>Multiple taxes:</b> you can write <font face='Courier'>tax: Tax(...)</font> "
    "for the simple case or <font face='Courier'>taxes: [vat, serviceTax]</font>. "
    "No country rules are hard-coded - we only use the percentage you give.",
    "<b>Discount</b> gets friendly constructors: "
    "<font face='Courier'>Discount.percentage(10)</font> and "
    "<font face='Courier'>Discount.fixed(50)</font>. The long form "
    "<font face='Courier'>Discount(type: DiscountType.percentage, value: 10)</font> "
    "also works.",
    "<b>Currency</b> has ready constants (usd, eur, gbp, inr, npr, aud, cad, "
    "jpy) and you can make your own: <font face='Courier'>Currency(code: 'NPR', "
    "symbol: 'Rs.', decimalDigits: 2)</font>. JPY uses 0 decimals.",
    "<b>Logo</b> can come from bytes, an asset or (only if you ask) the network.",
    "<b>Optional fields everywhere</b> - adding a new optional field in v1.1 "
    "does not break anyone. That is how we stay backward compatible.",
])
decision("You listed 'template configuration' as an Invoice field. I recommend "
         "<b>not</b> putting it inside Invoice. An invoice is data (what was "
         "sold); the template is presentation (how it looks). Instead: "
         "<font face='Courier'>InvoiceGenerator.generate(invoice, template: "
         "InvoiceTemplate.modern, theme: myTheme)</font>. Then the same invoice "
         "can be printed in any style, and saving invoices to a database never "
         "stores colours.")

story.append(PageBreak())

# --------------------------------------------------------------------------
# 6. Calculation
# --------------------------------------------------------------------------
h1("6. The calculation engine")
p("Money math is where invoice software most often goes wrong. Computers "
  "store decimals like 0.1 in binary and cannot store them exactly:")
code("""
print(0.1 + 0.2);      // 0.30000000000000004   (not 0.3!)
print(1.005 * 100);    // 100.49999999999999    (should be 100.5)
""")
h2("Our strategy: count in the smallest unit")
p("Internally we never add doubles. We convert every amount into "
  "<b>whole minor units</b> (cents for USD, paisa for NPR, yen for JPY) "
  "stored as exact integers, do the math, and convert back only for display. "
  "We read the number through its shortest text form (1.005 stays '1.005'), "
  "so the binary error never enters the calculation. This needs <b>no extra "
  "package</b>.")
simple("Instead of saying 'one dollar and five cents' (1.05) we say "
       "'105 cents'. Whole numbers never have rounding surprises.")

h2("The formula (worked example)")
table(["Step", "Rule", "Example"], [
    ["Line total", "quantity x unitPrice - item discount", "1 x 500 = 500.00 ; 2 x 100 = 200.00"],
    ["Subtotal", "sum of line totals", "700.00"],
    ["Discount", "invoice discount on the subtotal", "10% of 700 = 70.00"],
    ["Taxable amount", "subtotal - discount", "630.00"],
    ["Tax", "each tax % of the taxable amount", "VAT 13% of 630 = 81.90"],
    ["Total", "taxable amount + all taxes", "711.90"],
], [32, 70, 68])
h2("Rounding rules (documented in code and README)")
bullets([
    "Rounding happens to the currency's decimal places (2 for USD, 0 for JPY).",
    "Mode: <b>round half away from zero</b> (0.125 -> 0.13), the normal commercial rule.",
    "We round each line total, the discount and each tax amount once. "
    "The total is then an exact sum, so the numbers on the PDF always add up.",
    "If an item has its own tax, that item is taxed with its own rate; the "
    "invoice discount is shared across items in proportion to their value "
    "(leftover cents go to the lines with the largest remainder - see Chapter 3).",
])
p("The result is an immutable <font face='Courier'>InvoiceTotals</font> "
  "object: <font face='Courier'>subtotal, discountAmount, taxableAmount, "
  "taxLines (one per tax), taxAmount, total, lines</font>. Developers can "
  "use it without making a PDF at all:")
code("final totals = InvoiceCalculator.calculate(invoice);\nprint(totals.total); // 711.9")

story.append(PageBreak())

# --------------------------------------------------------------------------
# 7. PDF
# --------------------------------------------------------------------------
h1("7. PDF generation and templates")
h2("What generate() does")
flow([
    ("validate(invoice)", "throws InvoiceValidationException listing every problem"),
    ("InvoiceCalculator.calculate()", "exact totals"),
    ("load resources", "logo image + fonts (async - this is why generate is 'await')"),
    ("template builds sections", "header, bill-to, items table, summary, footer"),
    ("pw.MultiPage lays out pages", "long tables flow onto page 2, 3... automatically"),
    ("InvoicePdf result", "bytes, fileName, pageCount, totals"),
])
h2("What you get back")
code("""
final pdf = await InvoiceGenerator.generate(invoice);
pdf.bytes;      // Uint8List - upload it, email it, store it
pdf.fileName;   // 'INV-1001.pdf'
pdf.pageCount;  // 3
pdf.totals;     // the same numbers printed on the PDF
""")
p("Returning our own small <font face='Courier'>InvoicePdf</font> class "
  "(instead of raw bytes) means we can add fields later without breaking anyone.")

h2("Multiple pages")
p("The pdf package has a widget called <font face='Courier'>MultiPage</font>. "
  "We give it a long list of content; it fills page 1, then continues on "
  "page 2. The items table header row repeats on each new page, the big "
  "business header is drawn only on page 1, and every page gets "
  "'Page 2 of 3' in the footer. We will test 1, 10, 50 and 150 items and "
  "check the real page count.")

h2("Templates without copy-paste")
p("Every invoice has the same five <b>sections</b>. Shared section builders "
  "live in <font face='Courier'>pdf/sections/</font>. A template is a small "
  "class that decides how each section looks (colours, alignment, header "
  "band or not), reusing those builders.")
table(["Template", "Look"], [
    ["Classic", "Traditional: logo left, 'INVOICE' right, bordered table, grey header row."],
    ["Modern", "SaaS style: coloured header band, rounded summary card, zebra rows."],
    ["Minimal", "Lots of white space, thin lines, no fills, small type."],
], [30, 140])
decision("In v1, <font face='Courier'>InvoiceTemplate</font> exposes only the "
         "three built-in templates (<font face='Courier'>InvoiceTemplate.classic"
         "</font>, etc.). Opening it up for fully custom templates is planned, "
         "but doing it in v1 would freeze our internal drawing code as public "
         "API. Keeping it closed now lets us improve it freely.")

h2("Customization: InvoiceTheme and InvoiceLabels")
code("""
InvoiceTheme(
  primaryColor: PdfColor.fromHex('#2563EB'),
  secondaryColor: PdfColors.grey700,
  font: myFont, boldFont: myBoldFont,
  baseFontSize: 10, spacing: 12, borderRadius: 6,
  pageFormat: PdfPageFormat.a4,           // or PdfPageFormat.letter
  dateFormat: 'dd/MM/yyyy', locale: 'en_US',
)
InvoiceLabels(invoiceTitle: 'TAX INVOICE', billTo: 'Bill To', ...)
""")
p("Labels are separate so a Nepali or French developer can translate every "
  "word on the PDF without touching colours.")

story.append(PageBreak())

# --------------------------------------------------------------------------
# 8. Preview / output / errors
# --------------------------------------------------------------------------
h1("8. Preview, save, share, print")
h2("Preview widget")
p("<font face='Courier'>InvoicePreview(invoice: invoice)</font> is a Flutter "
  "widget. Two ways to build it:")
table(["Option", "Good", "Bad"], [
    ["A. Show the real PDF (recommended)", "Looks exactly like the PDF, "
     "always. Little code. Uses printing's PdfPreview.", "Slightly slower to appear."],
    ["B. Re-draw it with Flutter widgets", "Instant, scrollable.",
     "Two layouts to keep in sync - they WILL drift apart over time."],
], [52, 64, 54])
h2("Save / share / print")
table(["Platform", "Print", "Share", "Save"], [
    ["Android", "yes", "yes (share sheet)", "yes (app documents)"],
    ["iOS", "yes", "yes (share sheet)", "yes (app documents)"],
    ["macOS", "yes", "yes", "yes (needs sandbox file permission)"],
    ["Windows", "yes", "save dialog", "yes"],
    ["Linux", "yes", "save dialog", "yes"],
    ["Web", "browser print", "browser download", "browser download"],
], [30, 35, 55, 50])
p("<i>This table is from the printing package docs. In Phase 7 I will "
  "verify what I can on your Mac and clearly mark anything not tested.</i>")

h2("Error handling")
code("""
InvoiceException                    (base - catch everything)
 |-- InvoiceValidationException     bad data. Has .issues: a list like
 |                                  ['items[2].quantity must be >= 0',
 |                                   'tax VAT: percentage must be 0-100']
 |-- InvoiceImageException          logo missing / broken / unsupported
 `-- InvoiceGenerationException     anything else while building the PDF
""")
p("Validation collects <b>all</b> problems at once, so a developer fixes "
  "them in one go instead of one crash at a time. Rules: invoice number "
  "not empty, at least one item, quantity &gt;= 0, price &gt;= 0, tax 0-100%, "
  "percentage discount 0-100%, fixed discount not bigger than the subtotal, "
  "due date not before issue date.")

h2("QR codes")
p("Not mandatory in v1. Because 'pdf' already includes the barcode library, "
  "an optional <font face='Courier'>InvoiceQrCode</font> (payment URL, invoice "
  "URL or custom text) costs zero new dependencies. I reserve an optional "
  "field for it and plan it for Phase 5 as a small extra.")

story.append(PageBreak())

# --------------------------------------------------------------------------
# 9. Roadmap + git
# --------------------------------------------------------------------------
h1("9. The plan, phase by phase")
table(["Phase", "What", "You push after?"], [
    ["1", "Architecture plan + this guide (now)", "Yes - first commit"],
    ["2", "Convert to package, models, exports, model tests", "Yes"],
    ["3", "Calculation engine + many tests", "Yes"],
    ["4", "PDF generator + Classic template + multi-page tests", "Yes"],
    ["5", "Theme, labels, Modern + Minimal templates, (QR)", "Yes"],
    ["6", "InvoicePreview widget", "Yes"],
    ["7", "save / share / print + platform table", "Yes"],
    ["8", "Example app", "Yes"],
    ["9", "README, CHANGELOG, API docs", "Yes"],
    ["10", "pub.dev dry-run, fix everything", "Yes - then publish"],
], [16, 110, 44])
p("After every phase I stop, tell you what I did and how, add a chapter to "
  "this guide, and give you a commit message. I never commit or push - you do.")

h2("How to push (first time)")
code("""
cd /Users/prajan/Desktop/package/pdf_invoice
git init
git add .
git commit -m "docs: add architecture plan and learning guide (phase 1)"
git branch -M main
git remote add origin https://github.com/<you>/flutter_invoice_generator.git
git push -u origin main
""")
h2("Future pro features (not in the free core)")
p("Extra premium templates, advanced branding, custom sections, recurring "
  "invoices. The core stays a clean, free SDK - no payments or licences "
  "inside the package.")

# ==========================================================================
# CHAPTER 2 - Phase 2: package skeleton and models
# ==========================================================================
story.append(PageBreak())
h1("Chapter 2 - Phase 2: Skeleton and models")
p("In this phase we turned the folder into a real package, wrote every "
  "data model, the error classes, the public export file, and 42 tests. "
  "There is no PDF code yet - that is on purpose. We first make the data "
  "solid, then build on top of it.")

h2("Step 1 - From app to package")
table(["What we did", "Why"], [
    ["Deleted android/ ios/ web/ macos/ windows/ linux/, lib/main.dart, "
     "test/widget_test.dart",
     "A package has no app to run. Those folders were the default counter "
     "app. The demo app will live in example/ (Phase 8)."],
    ["Changed .metadata to <font face='Courier'>project_type: package</font>",
     "Tells the Flutter tool this is a package, not an app."],
    ["Renamed to <font face='Courier'>flutter_invoice_generator</font> in "
     "pubspec.yaml",
     "The name people will type in their pubspec. Users import "
     "<font face='Courier'>package:flutter_invoice_generator/...</font>."],
    ["Kept <font face='Courier'>publish_to: 'none'</font> for now",
     "A safety lock so nothing gets published by accident. Removed in Phase 10."],
    ["Only one dependency added: <font face='Courier'>meta</font>",
     "For <font face='Courier'>@immutable</font>. Flutter already ships it, "
     "so users download nothing new. pdf/printing come in Phase 4."],
    ["Stricter analysis_options.yaml",
     "Forces doc comments on every public API, trailing commas, final "
     "locals, strict types. pub.dev scores packages on this."],
], [70, 100])

h2("Step 2 - The models")
code("""
lib/src/models/
  currency.dart            Currency + 8 built-ins (usd, eur, gbp, inr,
                           npr, aud, cad, jpy) and Currency.values
  tax.dart                 Tax(name, percentage)
  discount.dart            Discount, DiscountType, .percentage(), .fixed()
  business.dart            seller (name required, the rest optional)
  customer.dart            buyer  (name required, the rest optional)
  payment_information.dart all optional + isEmpty
  invoice_logo.dart        InvoiceLogo.memory / .asset / .network
  invoice_detail.dart      extra header rows like 'PO Number'
  invoice_item.dart        one line
  invoice.dart             everything together
""")

h2("Five Dart ideas used everywhere (learn these!)")
p("<b>1. Immutable + final fields.</b> Every field is "
  "<font face='Courier'>final</font> and the class is marked "
  "<font face='Courier'>@immutable</font>. Once made, an invoice never changes.")
p("<b>2. Defensive copies.</b> If you pass a list to an Invoice and later "
  "change your list, the invoice must not change. So the constructor "
  "copies it:")
code("""
Invoice({required List<InvoiceItem> items, ...})
    : items = List.unmodifiable(items);   // copy + read-only
""")
p("<b>3. copyWith.</b> To 'edit' an immutable object you make a changed copy:")
code("final updated = invoice.copyWith(invoiceNumber: 'INV-1002');")
p("Note: with this common pattern, passing <font face='Courier'>null</font> "
  "means 'keep the old value', so copyWith cannot remove an optional field. "
  "We documented that.")
p("<b>4. Value equality (== and hashCode).</b> By default Dart says two "
  "objects are equal only if they are the <i>same object</i>. We override "
  "<font face='Courier'>==</font> so two invoices with the same data are "
  "equal. The rule: if you override ==, you must override hashCode the same "
  "way, or Sets and Maps break.")
p("<b>5. final class.</b> <font face='Courier'>final class Tax</font> means "
  "users cannot extend or implement Tax. That sounds strict, but it protects "
  "them: if we add a new field or method later, nobody's subclass breaks. "
  "This is a backward-compatibility tool.")
simple("Immutable means 'printed on paper': you can photocopy it with "
       "changes (copyWith), but you never erase the original.")

h2("Design decisions you will see in the code")
bullets([
    "<b>Numbers are <font face='Courier'>num</font>.</b> So both "
    "<font face='Courier'>quantity: 2</font> and "
    "<font face='Courier'>quantity: 2.5</font> work, and an "
    "<font face='Courier'>int</font> variable can be passed without "
    "<font face='Courier'>.toDouble()</font>. In Dart, "
    "<font face='Courier'>13 == 13.0</font> is true and their hashCodes "
    "match, so equality still works.",
    "<b>tax vs taxes.</b> Both Invoice and InvoiceItem accept "
    "<font face='Courier'>tax:</font> (one) or "
    "<font face='Courier'>taxes:</font> (many). Passing both throws an "
    "ArgumentError - in release builds too, not only in debug.",
    "<b>Item taxes have 3 meanings:</b> not set (null) = use the invoice "
    "taxes; a list = use these instead; "
    "<font face='Courier'>const []</font> = tax-exempt item.",
    "<b>Logo lives on Business.</b> The requirements listed a logo on both "
    "Invoice and Business. Two places for the same thing is confusing, so "
    "the seller's logo is <font face='Courier'>Business.logo</font>.",
    "<b>dueDate is optional</b> for 'due on receipt' invoices.",
    "<b>Currency defaults to USD</b> so the quick start stays short.",
    "<b>metadata vs details.</b> details are printed on the PDF (PO number); "
    "metadata is never printed (your database ID).",
    "<b>No QR field yet.</b> Adding an optional field later is not a "
    "breaking change, so we add it only when it actually works.",
])

h2("Step 3 - Sealed class for the logo")
code("""
sealed class InvoiceLogo {
  const factory InvoiceLogo.memory(Uint8List bytes) = MemoryInvoiceLogo;
  const factory InvoiceLogo.asset(String assetPath) = AssetInvoiceLogo;
  const factory InvoiceLogo.network(String url)     = NetworkInvoiceLogo;
}
""")
p("<font face='Courier'>sealed</font> means the compiler knows the full "
  "list of logo kinds. In Phase 4, when we load the logo with a "
  "<font face='Courier'>switch</font>, Dart will error if we forget one "
  "kind. Users only see <font face='Courier'>InvoiceLogo</font> - the three "
  "concrete classes are hidden with "
  "<font face='Courier'>export ... show InvoiceLogo</font>.")
p("A memory logo is equal to another only if it is the same byte buffer. "
  "Comparing two 2 MB images byte by byte every time you compare invoices "
  "would be slow.")

h2("Step 4 - Exceptions")
p("<font face='Courier'>InvoiceException</font> is the base class. It is "
  "deliberately <b>not</b> sealed: if it were, adding a new exception type "
  "in v1.2 would break users' exhaustive switch statements. "
  "<font face='Courier'>InvoiceValidationException</font> carries a list of "
  "<font face='Courier'>InvoiceValidationIssue(field, message)</font>, "
  "for example <font face='Courier'>items[1].quantity: must not be "
  "negative</font>. The validator that fills it comes in Phase 3, together "
  "with the calculator, because some rules (fixed discount bigger than the "
  "subtotal) need the totals.")

h2("Step 5 - The public door: one export file")
code("""
// lib/flutter_invoice_generator.dart
export 'src/models/invoice.dart';
export 'src/models/invoice_logo.dart' show InvoiceLogo;
...
""")
p("Internal helpers (<font face='Courier'>utils/equality.dart</font>, "
  "<font face='Courier'>utils/tax_merge.dart</font>) are <b>not</b> "
  "exported, so we can change them any time.")

h2("Step 6 - Tests (42 passing)")
table(["File", "What it proves"], [
    ["test/models/currency_test.dart", "8 required currencies, unique codes, "
     "JPY = 0 decimals, custom currency, equality, copyWith, bad decimals rejected"],
    ["test/models/tax_discount_test.dart", "decimal tax rates, 13 == 13.0, "
     "short and long Discount forms are equal, percentage != fixed"],
    ["test/models/parties_test.dart", "Business/Customer/Payment fields, "
     "payment without IBAN, logo equality rules"],
    ["test/models/invoice_item_test.dart", "quantities 1, 2, 2.5, 0.75; the "
     "3 tax meanings; both-tax error; list copied and read-only"],
    ["test/models/invoice_test.dart", "quick-start invoice, defaults, multiple "
     "taxes (CGST+SGST), immutability, equality, metadata key order"],
    ["test/exceptions/...", "messages list every issue; all catchable as "
     "InvoiceException"],
], [62, 108])
p("Tests import only <font face='Courier'>package:flutter_invoice_generator/"
  "flutter_invoice_generator.dart</font>, exactly like a real user. That "
  "also proves the exports are correct.")
code("""
flutter pub get
flutter analyze        ->  No issues found!
flutter test           ->  +42: All tests passed!
dart format lib test   ->  0 changed
""")
p("<b>Try it yourself:</b> change a value in "
  "<font face='Courier'>test/models/invoice_test.dart</font> so a test "
  "fails, then run <font face='Courier'>flutter test</font>.")
p("<b>Next (Phase 3):</b> InvoiceCalculator + InvoiceTotals + InvoiceValidator, the exact "
  "minor-unit money math, and many calculation tests (1 x $100, 10% "
  "discount, 13% tax, decimals, rounding, large values).")


# ==========================================================================
# CHAPTER 3 - Phase 3: calculation engine
# ==========================================================================
story.append(PageBreak())
h1("Chapter 3 - Phase 3: The calculation engine")
p("This phase is all about money math. No PDF yet - if the numbers are "
  "wrong, a beautiful PDF is worthless. We added 4 files and 65 new tests "
  "(107 in total).")
code("""
lib/src/calculation/
  money.dart             (internal) exact decimals, rounding, allocation
  totals_engine.dart     (internal) the math, in BigInt minor units
  invoice_totals.dart    (public)   InvoiceTotals, InvoiceLineTotals,
                                    InvoiceTaxLine
  invoice_calculator.dart(public)   InvoiceCalculator.calculate()
lib/src/validation/
  invoice_validator.dart (public)   InvoiceValidator.validate()
""")

h2("How to use it")
code("""
final totals = InvoiceCalculator.calculate(invoice);
totals.subtotal;           // 700.0
totals.discountAmount;     // 70.0
totals.taxableAmount;      // 630.0
totals.taxLines;           // [InvoiceTaxLine(VAT: 81.9)]
totals.total;              // 711.9
totals.totalInMinorUnits;  // 71190  (cents - for Stripe etc.)
totals.lines[0].lineTotal; // 500.0
""")

h2("Idea 1 - Never do money math with double")
p("A <font face='Courier'>double</font> stores numbers in binary. Most "
  "decimals (0.1, 1.005...) cannot be stored exactly, so tiny errors "
  "appear and then rounding goes the wrong way:")
code("""
1.005 * 100           // 100.49999999999999  -> rounds to 1.00  (wrong!)
our engine: 1.005     // exactly 1005 / 1000 -> rounds to 1.01  (right)
""")
p("<b>How we fixed it:</b> Dart prints every double in its shortest exact "
  "form (<font face='Courier'>1.005.toString() == '1.005'</font>). We read "
  "that text and turn it into two whole numbers: digits = 1005, scale = 3 "
  "(meaning 1005 / 10^3). This is <font face='Courier'>ExactDecimal</font> "
  "in money.dart. All math then uses <font face='Courier'>BigInt</font> "
  "(whole numbers of any size).")
simple("We stop writing '1.005 dollars' and write '1005 thousandths of a "
       "dollar'. Whole numbers are always exact.")

h2("Idea 2 - Why BigInt and not int?")
p("On Flutter Web, Dart's <font face='Courier'>int</font> is really a "
  "JavaScript number. It is only exact up to 2^53 (about 9 quadrillion). "
  "<font face='Courier'>quantity x price x 10^digits</font> can pass that "
  "for big invoices. BigInt has no limit and gives the same answer on "
  "Android, iOS, desktop and Web.")

h2("Idea 3 - Rounding: half away from zero")
table(["Exact value", "Rounded (2 decimals)", "Why"], [
    ["0.124", "0.12", "below half - down"],
    ["0.125", "0.13", "exactly half - away from zero (up)"],
    ["2.5 (JPY, 0 decimals)", "3", "not 2 - we do NOT use banker's rounding"],
    ["-0.125", "-0.13", "away from zero, symmetric"],
], [50, 50, 70])
p("The function is <font face='Courier'>roundDiv(numerator, denominator)</font>: "
  "divide, look at the remainder, and if remainder x 2 &gt;= denominator, "
  "move one step away from zero.")

h2("Idea 4 - Round each value once, then only add")
code("""
line   = round(quantity x unitPrice)  - round(item discount)
subtotal = sum(lines)                        <- exact, no rounding
discount = round(subtotal x %)  or fixed
taxable  = subtotal - discount               <- exact
tax      = round(taxable_for_that_rate x %)  <- once per tax rate
total    = taxable + sum(taxes)              <- exact
""")
p("Because every 'sum' step is exact, the PDF can never show numbers that "
  "do not add up. We have a test that builds <b>300 random invoices</b> and "
  "checks this for every single one.")
callout("Why round tax per rate, not per line?",
        "3 lines of 0.10 at 5%: per line 0.005 rounds to 0.01, times 3 = "
        "0.03. On the sum, 0.30 x 5% = 0.015 rounds to 0.02. Per-line "
        "rounding adds up rounding errors, so most accounting systems round "
        "tax on the total per rate. We do the same (there is a test for it).")

h2("Idea 5 - Sharing the discount fairly (largest remainder)")
p("If items have <b>different</b> tax rates, we must know how much of the "
  "invoice discount belongs to each line. Example: discount of $1.00 over "
  "three $1 items. 100 cents / 3 = 33.33 each.")
table(["Step", "Item A", "Item B", "Item C", "Sum"], [
    ["Exact share", "33.33", "33.33", "33.33", "99.99?"],
    ["Round down", "33", "33", "33", "99"],
    ["1 cent left - goes to largest remainder (tie: first)", "34", "33", "33", "100 OK"],
], [70, 25, 25, 25, 25])
p("This is <font face='Courier'>allocateProportionally()</font>. The shares "
  "always add up to exactly the discount. (In Chapter 1 I wrote 'leftover "
  "to last item'; largest remainder is fairer, so I changed it.)")

h2("Mixed taxes example (tested)")
table(["Item", "Line", "Share of 10% disc.", "Taxable", "Tax"], [
    ["A (uses invoice VAT 13%)", "100", "10", "90", "VAT 11.70"],
    ["B (own GST 5%)", "100", "10", "90", "GST 4.50"],
    ["C (taxes: const [] = exempt)", "100", "10", "90", "-"],
    ["Total", "300", "30", "270", "16.20 -> total 286.20"],
], [56, 20, 34, 22, 38])

h2("Idea 6 - The validator")
p("<font face='Courier'>InvoiceValidator.validate(invoice)</font> returns a "
  "list of problems (empty = valid). "
  "<font face='Courier'>calculate()</font> calls it first and throws "
  "<font face='Courier'>InvoiceValidationException</font> if anything is "
  "wrong. It works in two rounds:")
bullets([
    "<b>Round 1 - simple checks:</b> blank invoice number/names, no items, "
    "due date before issue date, negative or NaN quantity/price, tax not "
    "0-100%, blank or duplicated tax, percentage discount not 0-100%, "
    "negative fixed discount.",
    "<b>Round 2 - needs the math</b> (only if round 1 passed, because the "
    "math would crash on NaN): fixed discount bigger than its line or the "
    "subtotal, and totals bigger than 10^15 minor units.",
])
callout("A bug the tests caught",
        "An item with a $25 discount on a $20 line also made the subtotal "
        "negative, so the validator reported a second, confusing error on "
        "the invoice discount. Now it reports only the root cause. This is "
        "exactly why we write tests before building on top.",
        AMBER_BG, AMBER)
p("<b>Why 10^15?</b> Totals are returned as <font face='Courier'>double</font>. "
  "A double can hold any 15-digit number exactly. 10^15 cents is 10 "
  "trillion dollars - more than enough, and we can promise every value "
  "is exact.")

h2("Idea 7 - Public types you cannot construct")
p("<font face='Courier'>InvoiceTotals</font> has its constructor marked "
  "<font face='Courier'>@internal</font>. Only our calculator should make "
  "one. That lets us add a new field in v1.1 without breaking anyone, "
  "because nobody else calls the constructor. Same idea for "
  "<font face='Courier'>abstract final class InvoiceCalculator</font>: it "
  "only has static methods, cannot be created, and cannot be extended.")

h2("Tests added in this phase")
table(["File", "What it checks"], [
    ["test/calculation/money_test.dart", "exact parsing (1.005, 1e-7, 1e21), "
     "half-away rounding, percent, conversion back, allocation"],
    ["test/calculation/invoice_calculator_test.dart", "1x$100, 2x$100, "
     "multiple items, zero qty, decimal qty/price, 0.1+0.2, 100 x 0.01, "
     "10% / fixed / zero / 100% discount, item discounts, 13% tax, no tax, "
     "zero tax, CGST+SGST, mixed item taxes, per-rate rounding, 1.005, "
     "0.125, JPY, 3-decimal currency, large values, 300 random invoices"],
    ["test/validation/invoice_validator_test.dart", "every rule above, plus "
     "'reports every problem at once'"],
], [62, 108])
code("""
flutter analyze   ->  No issues found!
flutter test      ->  +107: All tests passed!

# Same tests on Web, using Brave (Chromium) instead of Chrome:
export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
flutter test --platform chrome   ->  +107: All tests passed!
""")
p("<b>Next (Phase 4):</b> add the <font face='Courier'>pdf</font> package, "
  "build <font face='Courier'>InvoiceGenerator.generate()</font> with the "
  "Classic template, fonts and logo loading; test 1-150 item invoices.")

doc = SimpleDocTemplate(str(OUT), pagesize=A4, leftMargin=20 * mm,
                        rightMargin=20 * mm, topMargin=18 * mm,
                        bottomMargin=20 * mm,
                        title="flutter_invoice_generator - Learning Guide",
                        author="flutter_invoice_generator")
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print(f"Wrote {OUT}")
