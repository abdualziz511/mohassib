import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/root_screen.dart';

class MohassibApp extends StatelessWidget {
  const MohassibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROFOF', // اسم التطبيق الجديد
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Adapts to user's device preference
      
      // Enforce RTL directionality globally for Arabic app
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const RootScreen(),
    );
  }
}
