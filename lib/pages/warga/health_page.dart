import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'tekanan_darah_page.dart';
import 'gad7_page.dart';
import 'reproduksi_page.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: 'Kesehatan', subtitle: 'Kelola data kesehatan Anda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _card(context, Icons.bloodtype_rounded, 'Tekanan Darah',
                    'Input & lihat riwayat tekanan darah',
                    const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFEF5350)]),
                    const TekananDarahPage()),
                  const SizedBox(height: 14),
                  _card(context, Icons.psychology_rounded, 'Kuesioner GAD-7',
                    'Isi kuesioner kesehatan mental',
                    const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)]),
                    const GAD7Page()),
                  const SizedBox(height: 14),
                  _card(context, Icons.pregnant_woman_rounded, 'Reproduksi',
                    'Catat data kesehatan reproduksi',
                    const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFCE93D8)]),
                    const ReproduksiPage()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext ctx, IconData icon, String title, String desc, LinearGradient grad, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.shadowMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
