import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  List<dynamic> _riwayatTD = [];
  List<dynamic> _riwayatGAD = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    ApiService.refreshNotifier.addListener(_loadProfile);
  }

  @override
  void dispose() {
    ApiService.refreshNotifier.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getMe();
      if (result['success'] == true) {
        _user = result['data'];
      }

      // Fetch latest history for real-time consistency
      final tdList = await _api.getRiwayatTD();
      _riwayatTD = tdList;
      
      final gadList = await _api.getRiwayatGAD();
      _riwayatGAD = gadList;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      } catch (e) {
        if (mounted) AppToast.error(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildHealthSummary(),
                  const SizedBox(height: 20),
                  _buildMenuSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user?['nama_lengkap'] ?? 'Pengguna';
    final nik = _user?['nik'] ?? '';
    final role = _user?['role'] ?? 'warga';

    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: Center(child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                )),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text('NIK: $nik', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(role.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSummary() {
    final status = _user?['status_kesehatan'];
    
    // Try to get latest from history first
    String tdValue = '-/-';
    if (_riwayatTD.isNotEmpty) {
      final latest = _riwayatTD.first;
      tdValue = '${latest['systolic'] ?? '-'}/${latest['diastolic'] ?? '-'}';
    } else if (status != null) {
      tdValue = status['tekanan_darah'] ?? '-/-';
    }

    String gadValue = 'Skor: -';
    if (_riwayatGAD.isNotEmpty) {
      final latest = _riwayatGAD.first;
      final skor = latest['skor'] ?? latest['total_skor'] ?? '-';
      gadValue = 'Skor: $skor';
    } else if (status != null) {
      gadValue = 'Skor: ${status['skor_gad'] ?? '-'}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Kesehatan Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _statItem('Tekanan Darah', tdValue, Icons.bloodtype_rounded, AppTheme.danger)),
              const SizedBox(width: 12),
              Expanded(child: _statItem('GAD-7', gadValue, Icons.psychology_rounded, AppTheme.info)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _menuItem(Icons.logout_rounded, 'Keluar', AppTheme.danger, _logout),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.shadowSm,
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
        ]),
      ),
    );
  }
}
