import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/customer_provider.dart';
import '../models/customer_model.dart';
import '../../home/home_provider.dart';
import '../../debts/models/debt_model.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCustomerDialog(context),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.customers.isEmpty) {
            return const Center(child: Text('لا يوجد عملاء مضافين'));
          }
          return ListView.builder(
            itemCount: prov.customers.length,
            itemBuilder: (context, index) {
              final c = prov.customers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(c.name[0])),
                title: Text(c.name),
                subtitle: Text(c.phone ?? 'بدون هاتف'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('الرصيد:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${c.currentBalance} ر.ي', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: c.currentBalance > 0 ? Colors.green : Colors.red
                      )
                    ),
                  ],
                ),
                onTap: () {
                  if (c.currentBalance > 0) {
                    _showPayDebtDialog(context, c);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العميل ليس عليه ديون حالياً.')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عميل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم العميل'),
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
                context.read<CustomerProvider>().addCustomer(CustomerModel(
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

  void _showPayDebtDialog(BuildContext context, CustomerModel customer) {
    final amtCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: 'سداد دفعة من الحساب');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسديد مبلغ من ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد الحالي: ${customer.currentBalance} ر.ي'),
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
              if (amt != null && amt > 0 && customer.id != null) {
                await context.read<CustomerProvider>().payDebtBulk(customer.id!, amt, notesCtrl.text);
                if (ctx.mounted) {
                  context.read<HomeProvider>().refresh();
                  context.read<DebtProvider>().loadAll();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('سداد وتحديث الرصيد'),
          ),
        ],
      ),
    );
  }
}
