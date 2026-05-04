import 'package:flutter/material.dart';
import 'package:mohassib/core/database/database_helper.dart';

/// شاشة إدارة تصنيفات المصروفات — إضافة / تعديل / حذف مع تقرير مرئي
class ExpenseCategoriesScreen extends StatefulWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  State<ExpenseCategoriesScreen> createState() =>
      _ExpenseCategoriesScreenState();
}

class _ExpenseCategoriesScreenState
    extends State<ExpenseCategoriesScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cats = await _db.getExpenseCategoriesFull();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  static const Map<String, IconData> _iconMap = {
    'home': Icons.home,
    'flash_on': Icons.flash_on,
    'local_shipping': Icons.local_shipping,
    'handshake': Icons.handshake,
    'no_food': Icons.no_food,
    'people': Icons.people,
    'build': Icons.build,
    'more_horiz': Icons.more_horiz,
  };

  IconData _icon(String? iconName) =>
      _iconMap[iconName] ?? Icons.label_outline;

  // ── إضافة تصنيف جديد ─────────────────────────────────────
  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة تصنيف جديد',
            style: TextStyle(color: Colors.white),
            textDirection: TextDirection.rtl),
        content: TextField(
          controller: ctrl,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اسم التصنيف',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF111116),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) { Navigator.pop(ctx); return; }
              final exists = _categories.any((c) => c['name'] == name);
              if (exists) {
                Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا التصنيف موجود بالفعل', textDirection: TextDirection.rtl), backgroundColor: Colors.orange));
                return;
              }
              await _db.addExpenseCategory(name);
              Navigator.pop(ctx);
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تمت إضافة التصنيف: $name', textDirection: TextDirection.rtl), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── تعديل اسم تصنيف ──────────────────────────────────────
  void _showEditDialog(Map<String, dynamic> cat) {
    final isDefault = (cat['is_default'] as int?) == 1;
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لا يمكن تعديل التصنيفات الافتراضية', textDirection: TextDirection.rtl),
        backgroundColor: Colors.orange));
      return;
    }
    final ctrl = TextEditingController(text: cat['name'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل: ${cat['name']}',
            style: const TextStyle(color: Colors.white),
            textDirection: TextDirection.rtl),
        content: TextField(
          controller: ctrl,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'الاسم الجديد',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF111116),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty || newName == cat['name']) { Navigator.pop(ctx); return; }
              await _db.renameExpenseCategory(cat['name'] as String, newName);
              Navigator.pop(ctx);
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم التعديل', textDirection: TextDirection.rtl), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── حذف تصنيف مخصص ──────────────────────────────────────
  void _confirmDelete(Map<String, dynamic> cat) {
    final isDefault = (cat['is_default'] as int?) == 1;
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لا يمكن حذف التصنيفات الافتراضية', textDirection: TextDirection.rtl),
        backgroundColor: Colors.orange));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف "${cat['name']}"؟',
            style: const TextStyle(color: Colors.white),
            textDirection: TextDirection.rtl),
        content: const Text(
          'سيتم حذف التصنيف فقط. المصروفات المرتبطة به لن تُحذف.',
          style: TextStyle(color: Colors.grey),
          textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await _db.deleteExpenseCategory(cat['name'] as String);
              Navigator.pop(ctx);
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🗑️ تم حذف "${cat['name']}"', textDirection: TextDirection.rtl), backgroundColor: Colors.red));
            },
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // ── تقرير توزيع المصروفات ────────────────────────────────
  void _showReport() async {
    final summary = await _db.getExpenseSummaryByCategory();
    if (!mounted) return;
    final totalAll = summary.values.fold(0.0, (s, v) => s + v);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('توزيع المصروفات حسب التصنيف',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('الإجمالي: ${totalAll.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(color: Colors.cyan, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: summary.isEmpty
                  ? const Center(child: Text('لا توجد بيانات مصروفات', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      controller: scroll,
                      children: summary.entries.map((e) {
                        final pct = totalAll > 0 ? (e.value / totalAll * 100) : 0.0;
                        final colors = [Colors.cyanAccent, Colors.orangeAccent, Colors.purpleAccent,
                          Colors.greenAccent, Colors.redAccent, Colors.blueAccent, Colors.amberAccent, Colors.tealAccent];
                        final color = colors[e.key.hashCode.abs() % colors.length];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFF111116),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.1))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('${e.value.toStringAsFixed(0)} ر.ي',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: Colors.white10,
                                  color: color,
                                  minHeight: 6),
                            ),
                            const SizedBox(height: 4),
                            Text('${pct.toStringAsFixed(1)}٪ من الإجمالي',
                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ]),
                        );
                      }).toList(),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('تصنيفات المصروفات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline, color: Colors.cyanAccent),
            tooltip: 'تقرير التوزيع',
            onPressed: _showReport,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة تصنيف', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _categories.isEmpty
              ? const Center(
                  child: Text('لا توجد تصنيفات', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final name      = cat['name'] as String;
                    final iconName  = cat['icon'] as String?;
                    final isDefault = (cat['is_default'] as int?) == 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isDefault
                                ? Colors.cyan.withOpacity(0.12)
                                : Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        // أيقونة التصنيف
                        trailing: CircleAvatar(
                          backgroundColor: Colors.cyan.withOpacity(0.1),
                          radius: 20,
                          child: Icon(_icon(iconName),
                              color: Colors.cyan, size: 18),
                        ),
                        title: Text(name,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: isDefault
                            ? const Text('افتراضي',
                                style: TextStyle(color: Colors.cyan, fontSize: 11))
                            : const Text('مخصص',
                                style: TextStyle(color: Colors.grey, fontSize: 11)),
                        // أزرار التعديل / الحذف
                        leading: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: isDefault ? Colors.grey : Colors.blueAccent,
                                size: 18),
                            onPressed: () => _showEditDialog(cat),
                            tooltip: 'تعديل',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: isDefault ? Colors.grey : Colors.redAccent,
                                size: 18),
                            onPressed: () => _confirmDelete(cat),
                            tooltip: 'حذف',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
