import 'package:flutter/material.dart';

class PrintBarcodeScreen extends StatefulWidget {
  const PrintBarcodeScreen({super.key});

  @override
  State<PrintBarcodeScreen> createState() => _PrintBarcodeScreenState();
}

class _PrintBarcodeScreenState extends State<PrintBarcodeScreen> {
  bool _showPrice = false;
  bool _isSelected = true;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB);
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text('طباعة الباركود', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]
                ),
                child: TextField(
                  textAlign: TextAlign.right,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'بحث عن منتج...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    suffixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Switch(
                      value: _showPrice,
                      onChanged: (v) => setState(() => _showPrice = v),
                      activeColor: Colors.blueAccent,
                      activeTrackColor: Colors.blueAccent.withOpacity(0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('عرض السعر على الملصق', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('طباعة الاسم والباركود فقط', style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 11)),
                      ],
                    )
                  ]
                )
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 16),

              // Product Item
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent),
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 8)]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() { if(_quantity > 1) _quantity--; }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.redAccent)),
                            child: const Icon(Icons.remove, color: Colors.redAccent, size: 16),
                          )
                        ),
                        const SizedBox(width: 16),
                        Text('$_quantity', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => setState(() { _quantity++; }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green)),
                            child: const Icon(Icons.add, color: Colors.green, size: 16),
                          )
                        ),
                      ]
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('مياه بلادي', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2A2E) : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text('6512612712812', style: TextStyle(color: isDark ? Colors.white54 : Colors.green.shade700, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: _isSelected,
                          onChanged: (v) => setState(() => _isSelected = v!),
                          activeColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        )
                      ]
                    )
                  ]
                )
              ),
              const Spacer(),
              
              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text('طباعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text('إنشاء باركود للمحدد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1652A5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                    )
                  )
                ]
              )
            ]
          )
        )
      )
    );
  }
}
