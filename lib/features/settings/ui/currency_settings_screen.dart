import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/currency_provider.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العملات والصرف')),
      body: Consumer<CurrencyProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.currencies.length,
            itemBuilder: (context, index) {
              final c = prov.currencies[index];
              return Card(
                child: ListTile(
                  title: Text('${c.name} (${c.code})'),
                  subtitle: Text('1 ${c.code} = ${c.exchangeRate} ريال يمني'),
                  trailing: c.code == 'YER' 
                      ? const Icon(Icons.lock_outline, color: Colors.grey)
                      : IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditRateDialog(context, prov, c),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditRateDialog(BuildContext context, CurrencyProvider prov, dynamic currency) {
    final ctrl = TextEditingController(text: currency.exchangeRate.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل صرف ${currency.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'السعر مقابل الريال اليمني'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final rate = double.tryParse(ctrl.text) ?? 0;
              if (rate > 0) {
                prov.updateExchangeRate(currency.id, rate);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
