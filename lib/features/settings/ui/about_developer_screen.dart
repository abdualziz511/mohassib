import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111116) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('عن المطور', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Developer Avatar with Glow
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Colors.cyan, Colors.blueAccent]),
                  boxShadow: [
                    BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                  ],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF1A1A24),
                  child: Icon(Icons.person, size: 70, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Name
            Text(
              'عبد العزيز الفهد',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            Text(
              'مطور تطبيقات فلاتر (Flutter Developer)',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey : Colors.grey.shade700),
            ),
            const SizedBox(height: 40),
            
            // Info Cards
            _buildInfoCard(
              context,
              icon: Icons.phone_android,
              title: 'رقم الهاتف',
              value: '775659026',
              onTap: () => _launchUrl('tel:775659026'),
            ),
            _buildInfoCard(
              context,
              icon: Icons.language,
              title: 'السيرة الذاتية (CV)',
              value: 'تصفح الملف الشخصي',
              color: Colors.cyan,
              onTap: () => _launchUrl('https://abdualziz511.github.io/Abdualaziz_alfahd_CV_1/'),
            ),
            
            const SizedBox(height: 60),
            // Quote or Vision
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '"نحن لا نبني مجرد أنظمة، بل نبني حلولاً ذكية تمنحك السيطرة الكاملة على مشروعك."',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String value, VoidCallback? onTap, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (color ?? Colors.blueAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color ?? Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600, fontSize: 12)),
                  Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.grey : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
