import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const String dbName = 'mohassib_v3.db';

  // ── تصدير النسخة الاحتياطية ─────────────────────────────────────
  static Future<void> exportBackup() async {
    try {
      final dbPath = join(await getDatabasesPath(), dbName);
      final file = File(dbPath);

      if (await file.exists()) {
        final now = DateTime.now();
        final fileName = 'mohassib_backup_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.db';
        
        // مشاركة الملف
        await Share.shareXFiles(
          [XFile(dbPath, name: fileName)],
          subject: 'نسخة احتياطية لنظام محاسب - $fileName',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── استيراد النسخة الاحتياطية ─────────────────────────────────────
  static Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // يمكن تقييدها بـ .db إذا لزم الأمر
      );

      if (result != null && result.files.single.path != null) {
        final newDbFile = File(result.files.single.path!);
        final dbPath = join(await getDatabasesPath(), dbName);
        
        // 1. إغلاق قاعدة البيانات الحالية أولاً (يجب التعامل مع هذا في DatabaseHelper إذا كان مفتوحاً)
        // لكن للتبسيط، سنقوم بنسخ الملف مباشرة. يفضل إعادة تشغيل التطبيق بعد الاستعادة.
        
        // 2. عمل نسخة احتياطية للملف الحالي قبل الاستبدال (Safety first)
        final currentDb = File(dbPath);
        if (await currentDb.exists()) {
          await currentDb.copy('$dbPath.bak');
        }

        // 3. استبدال الملف
        await newDbFile.copy(dbPath);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
