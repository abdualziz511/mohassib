import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mohassib/app.dart';
import 'package:mohassib/core/database/database_helper.dart';
import 'package:mohassib/features/products/provider/product_provider.dart';
import 'package:mohassib/features/sales/models/sales_models.dart';
import 'package:mohassib/features/expenses/models/expense_model.dart';
import 'package:mohassib/features/debts/models/debt_model.dart';
import 'package:mohassib/features/home/home_provider.dart';
import 'package:mohassib/features/purchases/provider/purchase_provider.dart';
import 'package:mohassib/features/suppliers/provider/supplier_provider.dart';
import 'package:mohassib/features/customers/provider/customer_provider.dart';
import 'package:mohassib/features/settings/provider/currency_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  // إخفاء شريط الحالة للشاشات المظلمة
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // تهيئة قاعدة البيانات
  await DatabaseHelper.instance.database;

  final cartProvider = CartProvider();
  await cartProvider.loadTaxRate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..loadAll(),
        ),
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider()..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtProvider()..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeProvider()..loadDashboard(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupplierProvider()..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => PurchaseProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider()..loadAll(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerProvider()..loadAll(),
        ),
      ],
      child: const MohassibApp(),
    ),
  );
}
