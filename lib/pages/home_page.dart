import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import 'warga/dashboard_page.dart';
import 'warga/chat_inbox_page.dart';
import 'warga/health_page.dart';
import 'warga/edukasi_page.dart';
import 'warga/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    HealthPage(),
    ChatInboxPage(),
    EdukasiPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await ApiService().getMe();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Responsive.radius(24)),
            topRight: Radius.circular(Responsive.radius(24)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Responsive.radius(24)),
            topRight: Radius.circular(Responsive.radius(24)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              _loadUserData(); // Refresh global user data
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: const Color(0xFF2D3436), // Clear dark color instead of grey
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.sp(11)),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: Responsive.sp(11)),
            iconSize: Responsive.icon(24),
            items: [
              _buildNavItem(Icons.dashboard_rounded, 'Beranda'),
              _buildNavItem(Icons.favorite_rounded, 'Kesehatan'),
              _buildNavItem(Icons.chat_bubble_rounded, 'Chat'),
              _buildNavItem(Icons.school_rounded, 'Edukasi'),
              _buildNavItem(Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }
}
