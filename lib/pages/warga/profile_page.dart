import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

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
      if (result['success'] == true) _user = result['data'];
      _riwayatTD = await _api.getRiwayatTD();
      _riwayatGAD = await _api.getRiwayatGAD();
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.logout();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      } catch (e) {
        if (mounted) AppToast.error(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(child: Column(children: [
              _buildProfileHeader(),
              SizedBox(height: Responsive.h(20)),
              _buildHealthSummary(),
              SizedBox(height: Responsive.h(20)),
              _buildMenuSection(),
              SizedBox(height: Responsive.h(30)),
            ])),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user?['nama_lengkap'] ?? 'Pengguna';
    final nik = _user?['nik'] ?? '';
    final role = _user?['role'] ?? 'warga';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: Responsive.pad(20)),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(Responsive.radius(32)), bottomRight: Radius.circular(Responsive.radius(32))),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.pad(24)),
          child: Row(children: [
            Container(
              width: Responsive.w(60), height: Responsive.w(60),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(Responsive.radius(18)), border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
              child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: Colors.white, fontSize: Responsive.sp(28), fontWeight: FontWeight.w900))),
            ),
            SizedBox(width: Responsive.w(16)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(name, style: TextStyle(color: Colors.white, fontSize: Responsive.sp(20), fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('NIK: $nik', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: Responsive.sp(12))),
              SizedBox(height: Responsive.h(8)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.pad(10), vertical: Responsive.pad(4)),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(Responsive.radius(12)), border: Border.all(color: Colors.white.withOpacity(0.3))),
                child: Text(role.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: Responsive.sp(10), fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildHealthSummary() {
    final status = _user?['status_kesehatan'];
    String tdValue = '-/-';
    if (_riwayatTD.isNotEmpty) { final l = _riwayatTD.first; tdValue = '${l['systolic'] ?? '-'}/${l['diastolic'] ?? '-'}'; }
    else if (status != null) tdValue = status['tekanan_darah'] ?? '-/-';
    String gadValue = 'Skor: -';
    if (_riwayatGAD.isNotEmpty) { final l = _riwayatGAD.first; gadValue = 'Skor: ${l['skor'] ?? l['total_skor'] ?? '-'}'; }
    else if (status != null) gadValue = 'Skor: ${status['skor_gad'] ?? '-'}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20)),
      child: Container(
        padding: EdgeInsets.all(Responsive.pad(18)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(20)), boxShadow: AppTheme.shadowMd),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status Kesehatan Terakhir', style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          SizedBox(height: Responsive.h(14)),
          Row(children: [
            Expanded(child: _statItem('Tekanan Darah', tdValue, Icons.bloodtype_rounded, AppTheme.danger)),
            SizedBox(width: Responsive.w(12)),
            Expanded(child: _statItem('GAD-7', gadValue, Icons.psychology_rounded, AppTheme.info)),
          ]),
        ]),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.pad(12)),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(Responsive.radius(14))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: Responsive.icon(20)),
        SizedBox(height: Responsive.h(8)),
        Text(label, style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textLight)),
        SizedBox(height: Responsive.h(2)),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20)),
      child: Column(children: [_menuItem(Icons.logout_rounded, 'Keluar', AppTheme.danger, _logout)]),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.h(10)),
        padding: EdgeInsets.all(Responsive.pad(14)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(Responsive.pad(10)),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(10))),
            child: Icon(icon, color: color, size: Responsive.icon(22)),
          ),
          SizedBox(width: Responsive.w(14)),
          Expanded(child: Text(title, style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w600, color: AppTheme.textDark))),
          Icon(Icons.arrow_forward_ios_rounded, size: Responsive.icon(16), color: AppTheme.textLight),
        ]),
      ),
    );
  }
}
