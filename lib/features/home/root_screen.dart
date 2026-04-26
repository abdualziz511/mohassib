import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import '../products/ui/products_screen.dart'; // تم استبدال التقارير بالمنتجات بناء على طلبك
import '../sales/ui/pos_screen.dart';
import '../expenses/ui/expenses_screen.dart'; 
import '../debts/ui/debts_screen.dart'; 
import '../sales/ui/sales_history_screen.dart';
import '../settings/ui/settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(), // المخزون / المنتجات
    const ExpensesScreen(),
    const DebtsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: _screens[_currentIndex],
      
      floatingActionButton: Container(
         decoration: BoxDecoration(
           shape: BoxShape.circle,
           boxShadow: isDark ? [] : [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4))]
         ),
         child: FloatingActionButton(
           backgroundColor: isDark ? Colors.blueAccent : Colors.white,
           foregroundColor: isDark ? Colors.white : Colors.blueAccent,
           elevation: isDark ? 6 : 0, // Using manual shadow instead for light mode glow
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
           child: const Icon(Icons.shopping_cart, size: 36),
           onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const POSScreen()));
           },
         )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomAppBar(
        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60, // Fixed height to prevent overflow
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_rounded, 'الرئيسية', 0),
              _buildNavItem(Icons.inventory_2_rounded, 'منتجاتي', 1), 
              
              const Spacer(flex: 2), 
              
              _buildNavItem(Icons.receipt_long_rounded, 'المصروفات', 2),
              _buildNavItem(Icons.account_balance_wallet_rounded, 'الديون', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.blueAccent : Colors.lightBlue;
    final inactiveColor = isDark ? Colors.grey.withOpacity(0.6) : Colors.black38;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      flex: 3,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
               padding: const EdgeInsets.all(4), // تقليل الحجم لعدم تجاوز الحدود
               decoration: BoxDecoration(
                  color: isSelected && !isDark ? Colors.cyan.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle
               ),
               child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label, 
              style: TextStyle(
                color: color, 
                fontSize: 10, // خط أصغر لتفادي الأخطاء
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
