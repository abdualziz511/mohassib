import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/customer_provider.dart';
import '../models/customer_model.dart';
import '../../home/home_provider.dart';
import '../../debts/models/debt_model.dart';
import '../../debts/ui/person_statement_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('العملاء', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.cyanAccent),
            onPressed: () => _showAddCustomerDialog(context),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.cyan));
          if (prov.customers.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.customers.length,
            itemBuilder: (context, index) {
              final c = prov.customers[index];
              return _buildCustomerCard(context, c, prov);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('لا يوجد عملاء مضافين', style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel c, CustomerProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.cyan.withOpacity(0.2),
          radius: 24,
          child: Text(c.name[0], style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(c.phone != null && c.phone!.isNotEmpty ? c.phone! : 'بدون هاتف', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('الرصيد: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${c.currentBalance.toStringAsFixed(0)} ر.ي', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: c.currentBalance > 0 ? Colors.greenAccent : (c.currentBalance < 0 ? Colors.redAccent : Colors.white)
                  )
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          color: const Color(0xFF1E1E2A),
          onSelected: (val) {
            if (val == 'edit') {
              _showAddCustomerDialog(context, customer: c);
            } else if (val == 'delete') {
              _confirmDelete(context, c, prov);
            } else if (val == 'pay') {
              if (c.currentBalance > 0) {
                _showPayDebtDialog(context, c);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العميل ليس عليه ديون حالياً.', textDirection: TextDirection.rtl)));
              }
            } else if (val == 'statement') {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PersonStatementScreen(personName: c.name, type: 'receivable')));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'statement', child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('كشف الحساب', style: TextStyle(color: Colors.white)), SizedBox(width: 8), Icon(Icons.receipt_long, color: Colors.blueAccent)])),
            const PopupMenuItem(value: 'pay', child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('تسديد دفعة', style: TextStyle(color: Colors.white)), SizedBox(width: 8), Icon(Icons.payments, color: Colors.greenAccent)])),
            const PopupMenuItem(value: 'edit', child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('تعديل', style: TextStyle(color: Colors.white)), SizedBox(width: 8), Icon(Icons.edit, color: Colors.orangeAccent)])),
            const PopupMenuItem(value: 'delete', child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('حذف', style: TextStyle(color: Colors.redAccent)), SizedBox(width: 8), Icon(Icons.delete, color: Colors.redAccent)])),
          ],
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PersonStatementScreen(personName: c.name, type: 'receivable')));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerModel customer, CustomerProvider prov) {
    if (customer.currentBalance > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حذف عميل عليه ديون، يرجى تصفية الحساب أولاً.', textDirection: TextDirection.rtl), backgroundColor: Colors.red));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('حذف العميل', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من حذف هذا العميل؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await prov.deleteCustomer(customer.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, {CustomerModel? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text(customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل', style: const TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'اسم العميل',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF111116),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF111116),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                final now = DateTime.now().toIso8601String();
                final prov = context.read<CustomerProvider>();
                bool ok = false;
                if (customer == null) {
                  ok = await prov.addCustomer(CustomerModel(
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    createdAt: now,
                    updatedAt: now,
                  ));
                } else {
                  ok = await prov.updateCustomer(customer.copyWith(
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    updatedAt: now,
                  ));
                }
                
                if (context.mounted) {
                  if (ok) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('فشل الحفظ. قد يكون الاسم موجود مسبقاً!', textDirection: TextDirection.rtl),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1A1A24),
        title: Text('تسديد مبلغ من ${customer.name}', style: const TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد الحالي: ${customer.currentBalance} ر.ي', style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF111116),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'البيان (ملاحظات)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF111116),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text);
              if (amt != null && amt > 0 && customer.id != null) {
                final excess = await context.read<CustomerProvider>().payDebtBulk(customer.id!, amt, notesCtrl.text);
                if (ctx.mounted) {
                  context.read<HomeProvider>().refresh();
                  context.read<DebtProvider>().loadAll();
                  
                  String msg = '✅ تم السداد بنجاح';
                  if (excess > 0) {
                    msg += '\nيوجد مبلغ زائد: ${excess.toStringAsFixed(0)} ر.ي لم يطبق على أي دين.';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(msg, textDirection: TextDirection.rtl),
                    backgroundColor: excess > 0 ? Colors.orange : Colors.green,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('سداد وتحديث الرصيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
