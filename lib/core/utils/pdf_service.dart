import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/sales/models/sales_models.dart';
import '../database/database_helper.dart';

class PdfService {
  static Future<void> generateInvoice(SaleModel sale, List<SaleItemModel> items) async {
    final pdf = pw.Document();
    
    // جلب الإعدادات (الشعار واسم المتجر)
    final settings = await DatabaseHelper.instance.getStoreSettings();
    final String storeName = settings?['store_name'] ?? 'متجري';
    final String storePhone = settings?['phone'] ?? '';
    final String storeAddress = settings?['address'] ?? '';
    final String? logoPath = settings?['logo_path'];
    
    pw.MemoryImage? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (file.existsSync()) {
        logoImage = pw.MemoryImage(file.readAsBytesSync());
      }
    }

    // تحميل خط كايرو الاحترافي للفواتير مع نظام أمان
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // قياس ورق الفواتير الصغير
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                pw.Text(storeName, style: pw.TextStyle(font: fontBold, fontSize: 16)),
                if (storePhone.isNotEmpty) pw.Text('هاتف: $storePhone', style: pw.TextStyle(font: font, fontSize: 10)),
                if (storeAddress.isNotEmpty) pw.Text('العنوان: $storeAddress', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                
                pw.Text('فاتورة مبيعات', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.SizedBox(height: 5),
                
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('رقم الفاتورة: ${sale.saleNumber}', style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.Text('التاريخ: ${sale.createdAt.substring(0, 16)}', style: pw.TextStyle(font: font, fontSize: 10)),
                      if (sale.customerName != null && sale.customerName!.isNotEmpty) 
                        pw.Text('العميل: ${sale.customerName}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Text('المنتج', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.right),
                      pw.Text('الكمية', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center),
                      pw.Text('الإجمالي', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.left),
                    ]),
                    pw.TableRow(children: [
                      pw.SizedBox(height: 5),
                      pw.SizedBox(height: 5),
                      pw.SizedBox(height: 5),
                    ]),
                    ...items.map((i) => pw.TableRow(children: [
                      pw.Text(i.productName, style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right),
                      pw.Text(i.quantity.toStringAsFixed(0), style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center),
                      pw.Text(i.total.toStringAsFixed(0), style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.left),
                    ])),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('الإجمالي النهائي:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Text('${sale.totalAmount.toStringAsFixed(0)} ر.ي', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ]),
                
                pw.SizedBox(height: 20),
                pw.Center(child: pw.Text('شكراً لزيارتكم', style: pw.TextStyle(font: fontBold, fontSize: 12))),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: sale.saleNumber.toString(),
                    width: 40 * PdfPageFormat.mm,
                    height: 10 * PdfPageFormat.mm,
                    drawText: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'فاتورة_مبيعات_${sale.saleNumber}.pdf',
    );
  }

  static Future<void> generateStatementPdf(String personName, double totalDebt, double totalPaid, double remaining, List<Map<String, dynamic>> statement, String storeName, String ownerName, bool isShare) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final settings = await DatabaseHelper.instance.getStoreSettings();
    final String? logoPath = settings?['logo_path'];
    
    pw.MemoryImage? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (file.existsSync()) {
        logoImage = pw.MemoryImage(file.readAsBytesSync());
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('تاريخ الطباعة: ${DateTime.now().toString().substring(0, 16)}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(storeName, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black)),
                          if (ownerName.isNotEmpty) pw.Text('المالك: $ownerName', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
                          pw.Text('كشف حساب للعميل/المورد', style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.blue800)),
                        ]
                      ),
                      if (logoImage != null) pw.SizedBox(width: 10),
                      if (logoImage != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                    ]
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Person Info & Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('الاسم: $personName', style: pw.TextStyle(font: fontBold, fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('الإجمالي: $totalDebt ر.ي', style: pw.TextStyle(font: font, color: PdfColors.orange700)),
                      pw.Text('المسدد: $totalPaid ر.ي', style: pw.TextStyle(font: font, color: PdfColors.green700)),
                      pw.Text('الرصيد المتبقي: $remaining ر.ي', style: pw.TextStyle(font: fontBold, color: remaining > 0 ? PdfColors.red700 : PdfColors.green700)),
                    ]
                  )
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            // Transactions Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: pw.TextStyle(font: font),
              cellAlignment: pw.Alignment.centerRight,
              cellPadding: const pw.EdgeInsets.all(8),
              data: [
                ['التاريخ', 'البيان (ملاحظات)', 'المبلغ', 'نوع الحركة'],
                ...statement.map((item) {
                  final isDebt = item['record_type'] == 'debt';
                  final amount = (item['amount'] as num).toDouble().toStringAsFixed(0);
                  final typeStr = isDebt ? 'دين (آجل)' : 'سداد دفعة';
                  final date = item['created_at'].toString().substring(0, 16);
                  final notes = item['notes'] ?? '';
                  
                  return [date, notes, amount, typeStr];
                }),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Stamp and Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('توقيع المحاسب / الإدارة', style: pw.TextStyle(font: fontBold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                  ],
                ),
                pw.Container(
                  width: 90,
                  height: 90,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red700, width: 1.5),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('مُعتمد', style: pw.TextStyle(font: fontBold, color: PdfColors.red700, fontSize: 10)),
                        pw.Text(storeName, style: pw.TextStyle(font: fontBold, color: PdfColors.red700, fontSize: 10), textAlign: pw.TextAlign.center),
                        pw.Text(DateTime.now().toString().substring(0, 10), style: pw.TextStyle(font: font, color: PdfColors.red700, fontSize: 7)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('تم الإصدار بواسطة: ${ownerName.isNotEmpty ? ownerName : storeName}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              ]
            ),
            pw.Center(
              child: pw.Text('نظام محاسب - لضمان الشفافية والمصداقية', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
            ),
          ];
        },
      ),
    );

    if (isShare) {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'كشف_حساب_$personName.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'كشف_حساب_$personName.pdf',
      );
    }
  }

  static Future<void> generateBarcodeLabels({
    required List<Map<String, dynamic>> items, // Each item: {name, barcode, price, qty}
    bool showPrice = true,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(38 * PdfPageFormat.mm, 25 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];
          for (var item in items) {
            final qty = item['qty'] as int;
            for (int i = 0; i < qty; i++) {
              widgets.add(
                pw.Container(
                  width: 34 * PdfPageFormat.mm,
                  height: 21 * PdfPageFormat.mm,
                  padding: const pw.EdgeInsets.all(1),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(item['name'], style: pw.TextStyle(font: font, fontSize: 7), maxLines: 1, overflow: pw.TextOverflow.clip, textDirection: pw.TextDirection.rtl),
                      pw.SizedBox(height: 1),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: item['barcode'],
                        width: 30 * PdfPageFormat.mm,
                        height: 10 * PdfPageFormat.mm,
                        drawText: true,
                        textStyle: pw.TextStyle(font: font, fontSize: 6),
                      ),
                      if (showPrice)
                        pw.Text('السعر: ${item['price']} ر.ي', style: pw.TextStyle(font: font, fontSize: 7), textDirection: pw.TextDirection.rtl),
                    ],
                  ),
                ),
              );
            }
          }
          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ملصقات_باركود.pdf',
    );
  }
}
