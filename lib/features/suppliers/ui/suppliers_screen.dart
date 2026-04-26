import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/supplier_provider.dart';
import '../models/supplier_model.dart';
import '../../home/home_provider.dart';
import '../../debts/models/debt_model.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSupplierDialog(context),
          ),
        ],
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.suppliers.isEmpty) {
            return const Center(child: Text('لا يوجد موردين مضافين'));
          }
          return ListView.builder(
            itemCount: prov.suppliers.length,
            itemBuilder: (context, index) {
              final s = prov.suppliers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(s.name[0])),
                title: Text(s.name),
                subtitle: Text(s.phone ?? 'بدون هاتف'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('الرصيد:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${s.currentBalance} ر.ي', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: s.currentBalance > 0 ? Colors.red : Colors.green
                      )
                    ),
                  ],
                ),
                onTap: () {
                  if (s.currentBalance > 0) {
                    _showPayDebtDialog(context, s);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المورد ليس له ديون حالياً.')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مورد جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المورد'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final now = DateTime.now().toIso8601String();
                context.read<SupplierProvider>().addSupplier(SupplierModel(
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  createdAt: now,
                  updatedAt: now,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPayDebtDialog(BuildContext context, SupplierModel supplier) {
    final amtCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: 'سداد دفعة للمورد');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسديد مبلغ لـ ${supplier.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد الحالي: ${supplier.currentBalance} ر.ي'),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'المبلغ المدفوع'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'البيان (ملاحظات)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text);
              if (amt != null && amt > 0 && supplier.id != null) {
                await context.read<SupplierProvider>().payDebtBulk(supplier.id!, amt, notesCtrl.text);
                if (ctx.mounted) {
                  context.read<HomeProvider>().refresh();
                  context.read<DebtProvider>().loadAll();
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('سداد وتحديث الرصيد'),
          ),
        ],
      ),
    );
  }
}
