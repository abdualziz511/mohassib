import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:mohassib/features/sales/models/sales_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await DatabaseHelper.instance.getStoreSettings();
    if (s != null) {
      _nameCtrl.text = s['name'] ?? '';
      _taxCtrl.text = (s['tax_rate'] ?? 0).toString();
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
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _label('اسم المتجرررررر / الشركة'),
            _field(_nameCtrl, 'مثال: سوبر ماركت البركة', Icons.store),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _label('العملة'),
                _field(_currencyCtrl, 'ر.ي', Icons.payments),
              ])),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _label('نسبة الضريبة %'),
                _field(_taxCtrl, '0', Icons.percent, type: TextInputType.number),
              ])),
            ]),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
            _infoCard('ملاحظة: تظهر هذه البيانات في رأس الفاتورة عند الطباعة ويتم احتساب الضريبة تلقائياً في السلة بناءً على النسبة المحددة هنا.'),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) => Container(
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
    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withOpacity(0.1))),
    child: Text(t, textAlign: TextAlign.right, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, height: 1.5)),
  );

  Future<void> _save() async {
    await DatabaseHelper.instance.updateStoreSettings(
      name: _nameCtrl.text.trim(),
      taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      currency: _currencyCtrl.text.trim(),
    );
    if (!mounted) return;
    // تحديث الضريبة في الـ Provider فوراً
    context.read<CartProvider>().loadTaxRate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم حفظ الإعدادات بنجاح', textDirection: TextDirection.rtl), backgroundColor: Colors.green));
  }
}
