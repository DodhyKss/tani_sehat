import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';
import 'tekanan_darah_page.dart';
import 'gad7_page.dart';
import 'reproduksi_page.dart';
import '../../services/api_service.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = ApiService().currentUser;
    final isFemale = user?['jenis_kelamin']?.toString().toLowerCase() == 'perempuan';

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: 'Kesehatan', subtitle: 'Kelola data kesehatan Anda'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.pad(20)),
              child: Column(
                children: [
                  _card(context, Icons.bloodtype_rounded, 'Tekanan Darah',
                    'Input & lihat riwayat tekanan darah',
                    const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFEF5350)]),
                    const TekananDarahPage()),
                  SizedBox(height: Responsive.h(14)),
                  _card(context, Icons.psychology_rounded, 'Kuesioner GAD-7',
                    'Isi kuesioner kesehatan mental',
                    const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)]),
                    const GAD7Page()),
                  if (isFemale) ...[
                    SizedBox(height: Responsive.h(14)),
                    _card(context, Icons.pregnant_woman_rounded, 'Reproduksi',
                      'Catat data kesehatan reproduksi',
                      const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFCE93D8)]),
                      const ReproduksiPage()),
                  ],
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
        padding: EdgeInsets.all(Responsive.pad(18)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(20)), boxShadow: AppTheme.shadowMd),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(Responsive.pad(12)),
            decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(Responsive.radius(14))),
            child: Icon(icon, color: Colors.white, size: Responsive.icon(26)),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: Responsive.sp(16), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            SizedBox(height: Responsive.h(4)),
            Text(desc, style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textMedium)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: Responsive.icon(18), color: AppTheme.textLight),
        ]),
      ),
    );
  }
}
