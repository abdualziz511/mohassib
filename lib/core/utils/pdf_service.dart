import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/sales/models/sales_models.dart';

class PdfService {
  static Future<void> generateInvoice(SaleModel sale, List<SaleItemModel> items) async {
    final pdf = pw.Document();
    
    // تحميل خط عربي يدعم PDF (مثل Tajawal أو Arial)
    // ملاحظة: ستحتاج لإضافة ملف الخط للأصول لاحقاً، حالياً سنستخدم الخط الافتراضي المدعوم
    final font = await PdfGoogleFonts.tajawalMedium();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // قياس ورق الفواتير الصغير
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Center(child: pw.Text('فاتورة مبيعات', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold))),
                pw.Divider(),
                pw.Text('رقم الفاتورة: ${sale.saleNumber}', style: pw.TextStyle(font: font)),
                pw.Text('التاريخ: ${sale.createdAt.substring(0, 16)}', style: pw.TextStyle(font: font)),
                if (sale.customerName != null) pw.Text('العميل: ${sale.customerName}', style: pw.TextStyle(font: font)),
                pw.Divider(),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Text('الإجمالي', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
                      pw.Text('الكمية', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
                      pw.Text('المنتج', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
                    ]),
                    ...items.map((i) => pw.TableRow(children: [
                      pw.Text(i.total.toStringAsFixed(0)),
                      pw.Text(i.quantity.toString()),
                      pw.Text(i.productName, style: pw.TextStyle(font: font)),
                    ])),
                  ],
                ),
                pw.Divider(),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text(sale.totalAmount.toStringAsFixed(0), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('الإجمالي النهائي:', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
                ]),
                pw.SizedBox(height: 20),
                pw.Center(child: pw.Text('شكراً لزيارتكم', style: pw.TextStyle(font: font))),
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
    final font = await PdfGoogleFonts.tajawalMedium();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('تاريخ الطباعة: ${DateTime.now().toString().substring(0, 16)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(storeName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      if (ownerName.isNotEmpty) pw.Text('المالك: $ownerName', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.Text('كشف حساب للعميل/المورد', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
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
                  pw.Text('الاسم: $personName', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('الإجمالي: $totalDebt ر.ي', style: const pw.TextStyle(color: PdfColors.orange700)),
                      pw.Text('المسدد: $totalPaid ر.ي', style: const pw.TextStyle(color: PdfColors.green700)),
                      pw.Text('الرصيد المتبقي: $remaining ر.ي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: remaining > 0 ? PdfColors.red700 : PdfColors.green700)),
                    ]
                  )
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            // Transactions Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
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
                    pw.Text('توقيع المحاسب / الإدارة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
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
                        pw.Text('مُعتمد', style: pw.TextStyle(color: PdfColors.red700, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(storeName, style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
                        pw.Text(DateTime.now().toString().substring(0, 10), style: const pw.TextStyle(color: PdfColors.red700, fontSize: 7)),
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
                pw.Text('تم الإصدار بواسطة: ${ownerName.isNotEmpty ? ownerName : storeName}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ]
            ),
            pw.Center(
              child: pw.Text('نظام محاسب - لضمان الشفافية والمصداقية', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
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
}
