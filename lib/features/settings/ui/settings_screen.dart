import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:mohassib/features/sales/models/sales_models.dart';
import 'package:mohassib/core/utils/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _ownerCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxCtrl     = TextEditingController();
  final _currencyCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _taxCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await DatabaseHelper.instance.getStoreSettings();
    if (s != null) {
      _nameCtrl.text    = s['store_name'] ?? '';
      _ownerCtrl.text   = s['owner_name'] ?? '';
      _phoneCtrl.text   = s['phone'] ?? '';
      _addressCtrl.text = s['address'] ?? '';
      _taxCtrl.text     = (s['tax_rate'] ?? 0).toString();
      _currencyCtrl.text = s['currency'] ?? 'ر.ي';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        title: const Text('إعدادات المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // ─── معلومات المتجر ───────────────────────────────
                  _sectionHeader('معلومات المتجر', Icons.store_outlined, Colors.cyanAccent),
                  const SizedBox(height: 12),
                  _label('اسم المتجر / الشركة'),
                  _field(_nameCtrl, 'مثال: سوبر ماركت البركة', Icons.store),
                  const SizedBox(height: 16),
                  _label('اسم صاحب المتجر'),
                  _field(_ownerCtrl, 'مثال: أحمد محمد', Icons.person_outline),
                  const SizedBox(height: 16),
                  _label('رقم الهاتف (يظهر في الفاتورة)'),
                  _field(_phoneCtrl, 'مثال: 777123456', Icons.phone_outlined,
                      type: TextInputType.phone),
                  const SizedBox(height: 16),
                  _label('العنوان (يظهر في الفاتورة)'),
                  _field(_addressCtrl, 'مثال: صنعاء - شارع الستين', Icons.location_on_outlined),
                  const SizedBox(height: 28),

                  // ─── إعدادات المالية ──────────────────────────────
                  _sectionHeader('الإعدادات المالية', Icons.attach_money, Colors.greenAccent),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _label('العملة'),
                      _field(_currencyCtrl, 'ر.ي', Icons.payments_outlined),
                    ])),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _label('نسبة الضريبة %'),
                      _field(_taxCtrl, '0', Icons.percent,
                          type: TextInputType.number),
                    ])),
                  ]),
                  const SizedBox(height: 40),

                  // ─── زر الحفظ ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                      label: const Text('حفظ الإعدادات',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _infoCard('ملاحظة: تظهر هذه البيانات في رأس الفاتورة عند الطباعة ويتم احتساب الضريبة تلقائياً في السلة بناءً على النسبة المحددة هنا.'),
                  
                  const SizedBox(height: 40),
                  // ─── قسم النسخ الاحتياطي ─────────────────────────────
                  _sectionHeader('البيانات والنسخ الاحتياطي', Icons.backup_outlined, Colors.orangeAccent),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _backupTile(
                      'استعادة', Icons.settings_backup_restore, Colors.orangeAccent, _handleRestore)),
                    const SizedBox(width: 12),
                    Expanded(child: _backupTile(
                      'نسخ احتياطي', Icons.cloud_upload_outlined, Colors.blueAccent, _handleBackup)),
                  ]),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Icon(icon, color: color, size: 18),
    ]),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? type}) =>
    Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: c,
        textAlign: TextAlign.right,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          suffixIcon: Icon(icon, color: Colors.cyan, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );

  Widget _infoCard(String t) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blueAccent.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
    ),
    child: Text(t, textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.blueAccent, fontSize: 12, height: 1.6)),
  );

  Widget _backupTile(String t, IconData i, Color c, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(i, color: c, size: 28),
        const SizedBox(height: 8),
        Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    ),
  );

  Future<void> _save() async {
    await DatabaseHelper.instance.updateStoreSettings(
      name:     _nameCtrl.text.trim(),
      taxRate:  double.tryParse(_taxCtrl.text) ?? 0,
      currency: _currencyCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
      address:  _addressCtrl.text.trim(),
    );
    if (!mounted) return;
    context.read<CartProvider>().loadTaxRate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ تم حفظ الإعدادات بنجاح', textDirection: TextDirection.rtl),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> _handleBackup() async {
    try {
      await BackupService.exportBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم تصدير النسخة الاحتياطية بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ في النسخ الاحتياطي: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _handleRestore() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('تنبيه هام', style: TextStyle(color: Colors.white), textDirection: TextDirection.rtl),
        content: const Text('استعادة نسخة احتياطية سيؤدي إلى حذف البيانات الحالية واستبدالها. هل تريد المتابعة؟ يفضل إعادة تشغيل التطبيق بعد العملية.', 
            style: TextStyle(color: Colors.grey), textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final success = await BackupService.importBackup();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ تم استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق.', textDirection: TextDirection.rtl),
                    backgroundColor: Colors.green,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ في الاستعادة: $e'), backgroundColor: Colors.redAccent));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('تأكيد الاستعادة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
