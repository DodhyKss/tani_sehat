import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'tekanan_darah_page.dart';
import 'gad7_page.dart';
import 'reproduksi_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _statusKesehatan;
  bool _harusIsiTD = false;
  bool _harusIsiGAD = false;
  List<dynamic> _riwayatTD = [];
  List<dynamic> _riwayatGAD = [];
  bool _hasShownModal = false;
  Map<String, dynamic>? _jadwalData;

  @override
  void initState() {
    super.initState();
    _loadData();
    ApiService.refreshNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    ApiService.refreshNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final meResult = await _api.getMe();
      if (meResult['success'] == true) {
        _userData = meResult['data'];
        _statusKesehatan = _userData?['status_kesehatan'];
      }
      try {
        final jadwalStatus = await _api.cekJadwal('');
        _jadwalData = jadwalStatus['data'];
        if (_jadwalData != null) {
          _harusIsiTD = _jadwalData?['td']?['is_waiting'] == false;
          _harusIsiGAD = _jadwalData?['gad7']?['is_waiting'] == false;
        }
      } catch (_) {}
      try { _riwayatTD = (await _api.getRiwayatTD()).take(7).toList(); } catch (_) {}
      try { _riwayatGAD = (await _api.getRiwayatGAD()).take(7).toList(); } catch (_) {}
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }



  void _showNotTimeDialog(String title, String? nextDate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.timer_rounded, color: AppTheme.accentWarm),
          const SizedBox(width: 10),
          Flexible(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Anda sudah melakukan pengisian untuk jadwal ini.'),
          const SizedBox(height: 12),
          Text('Jadwal pengisian berikutnya:', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
          const SizedBox(height: 4),
          Text(nextDate ?? 'Segera', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w700)))],
      ),
    );
  }

  Widget _modalButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: Responsive.h(50),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: Responsive.icon(22)),
        label: Text(text, style: TextStyle(color: Colors.white, fontSize: Responsive.sp(14), fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(14))), elevation: 0),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    if (_isLoading && _userData == null && _riwayatTD.isEmpty) {
      return const Scaffold(backgroundColor: AppTheme.scaffoldBg, body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    final name = _userData?['nama_lengkap'] ?? 'Pengguna';
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(firstName, name),
            SizedBox(height: Responsive.h(16)),
            if (_harusIsiTD || _harusIsiGAD) ...[
              _sectionTitle('⏰ Pengingat'),
              if (_harusIsiTD) _buildReminderCard('Tekanan Darah', 'Saatnya mengisi data tekanan darah Anda', Icons.bloodtype_rounded, AppTheme.danger),
              if (_harusIsiGAD) _buildReminderCard('Kuesioner GAD-7', 'Saatnya mengisi kuesioner kesehatan mental', Icons.psychology_rounded, AppTheme.info),
              SizedBox(height: Responsive.h(12)),
            ],
            _sectionTitle('📊 Status Kesehatan'),
            _buildHealthStatusCards(),
            SizedBox(height: Responsive.h(20)),
            _sectionTitle('⚡ Aksi Cepat'),
            _buildQuickActions(),
            SizedBox(height: Responsive.h(24)),
            _sectionTitle('📈 Riwayat Tekanan Darah (7 Terakhir)'),
            _buildTDHistory(),
            SizedBox(height: Responsive.h(24)),
            _sectionTitle('📉 Riwayat GAD-7 (7 Terakhir)'),
            _buildGADHistory(),
            SizedBox(height: Responsive.h(32)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20), vertical: Responsive.pad(10)),
      child: Text(title, style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
    );
  }

  Widget _buildHeader(String firstName, String fullName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(Responsive.pad(24), 0, Responsive.pad(24), Responsive.pad(20)),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(Responsive.radius(32)), bottomRight: Radius.circular(Responsive.radius(32))),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $firstName! 👋', style: TextStyle(color: Colors.white, fontSize: Responsive.sp(24), fontWeight: FontWeight.w900, letterSpacing: -1)),
            SizedBox(height: Responsive.h(4)),
            Text('Pantau kesehatan Anda hari ini', style: TextStyle(color: Colors.white.withAlpha(210), fontSize: Responsive.sp(13))),
          ])),
          Container(
            padding: EdgeInsets.all(Responsive.pad(10)),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(Responsive.radius(16)), border: Border.all(color: Colors.white.withAlpha(30))),
            child: ClipOval(child: Image.asset('assets/images/logo.png', width: Responsive.w(28), height: Responsive.w(28), fit: BoxFit.cover)),
          ),
        ]),
      ),
    );
  }

  Widget _buildReminderCard(String title, String message, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.pad(20), vertical: Responsive.pad(4)),
      padding: EdgeInsets.all(Responsive.pad(14)),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(Responsive.radius(16)), border: Border.all(color: color.withAlpha(70))),
      child: Row(children: [
        Container(padding: EdgeInsets.all(Responsive.pad(10)), decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(Responsive.radius(12))), child: Icon(icon, color: color, size: Responsive.icon(22))),
        SizedBox(width: Responsive.w(12)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.sp(13), color: color)),
          SizedBox(height: Responsive.h(2)),
          Text(message, style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textMedium)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, size: Responsive.icon(16), color: color),
      ]),
    );
  }

  Widget _buildHealthStatusCards() {
    if (_isLoading) return Center(child: Padding(padding: EdgeInsets.all(Responsive.pad(30)), child: const CircularProgressIndicator(color: AppTheme.primary)));
    String tekananDarah = '-/-', kategoriTD = '-';
    if (_riwayatTD.isNotEmpty) { final l = _riwayatTD.first; tekananDarah = '${l['systolic'] ?? '-'}/${l['diastolic'] ?? '-'}'; kategoriTD = l['kategori'] ?? '-'; }
    else if (_statusKesehatan != null) { tekananDarah = _statusKesehatan?['tekanan_darah'] ?? '-/-'; kategoriTD = _statusKesehatan?['kategori_td'] ?? '-'; }
    String skorGAD = '-', kategoriGAD = '-';
    if (_riwayatGAD.isNotEmpty) { final l = _riwayatGAD.first; skorGAD = (l['skor'] ?? l['total_skor'] ?? '-').toString(); kategoriGAD = l['kategori'] ?? '-'; }
    else if (_statusKesehatan != null) { skorGAD = _statusKesehatan?['skor_gad']?.toString() ?? '-'; kategoriGAD = _statusKesehatan?['kategori_gad'] ?? '-'; }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20)),
      child: Row(children: [
        Expanded(child: _buildStatusCard('Tekanan Darah', tekananDarah, _formatKategori(kategoriTD), Icons.bloodtype_rounded, _getKategoriColor(kategoriTD))),
        SizedBox(width: Responsive.w(12)),
        Expanded(child: _buildStatusCard('GAD-7', 'Skor: $skorGAD', _formatKategori(kategoriGAD), Icons.psychology_rounded, _getGADColor(kategoriGAD))),
      ]),
    );
  }

  Widget _buildStatusCard(String title, String value, String category, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.pad(14)),
      decoration: BoxDecoration(
        color: color.withAlpha(15), borderRadius: BorderRadius.circular(Responsive.radius(20)),
        border: Border.all(color: color.withAlpha(40), width: 1.5),
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(Responsive.pad(8)), decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(Responsive.radius(10))), child: Icon(icon, color: color, size: Responsive.icon(18))),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Responsive.pad(6), vertical: Responsive.pad(3)),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Responsive.radius(6))),
            child: Text(category, style: TextStyle(fontSize: Responsive.sp(8), fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ]),
        SizedBox(height: Responsive.h(12)),
        Text(title, style: TextStyle(fontSize: Responsive.sp(11), color: color.withOpacity(0.7), fontWeight: FontWeight.w600)),
        SizedBox(height: Responsive.h(4)),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: Responsive.sp(20), fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5))),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20)),
      child: GridView.count(
        crossAxisCount: Responsive.gridColumns,
        crossAxisSpacing: Responsive.w(14),
        mainAxisSpacing: Responsive.w(10),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: [
          _buildActionItem(Icons.bloodtype_rounded, 'Tensi', AppTheme.danger, () {
            if (_harusIsiTD) { Navigator.push(context, MaterialPageRoute(builder: (_) => const TekananDarahPage())).then((_) => _loadData()); }
            else { _showNotTimeDialog('Tekanan Darah', _jadwalData?['td']?['next_cek']); }
          }),
          _buildActionItem(Icons.psychology_rounded, 'GAD-7', AppTheme.info, () {
            if (_harusIsiGAD) { Navigator.push(context, MaterialPageRoute(builder: (_) => const GAD7Page())).then((_) => _loadData()); }
            else { _showNotTimeDialog('Kuesioner GAD-7', _jadwalData?['gad7']?['next_cek']); }
          }),
          if (_userData?['jenis_kelamin']?.toString().toLowerCase() == 'perempuan')
            _buildActionItem(Icons.water_drop_rounded, 'Reproduksi', const Color(0xFFAB47BC), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReproduksiPage())).then((_) => _loadData());
            }),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Expanded(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(14)), boxShadow: AppTheme.shadowSm),
          child: Center(child: Container(
            padding: EdgeInsets.all(Responsive.pad(8)),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: Responsive.icon(20)),
          )),
        )),
        SizedBox(height: Responsive.h(6)),
        Text(label, style: TextStyle(fontSize: Responsive.sp(10), fontWeight: FontWeight.w600, color: AppTheme.textMedium), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildTDHistory() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_riwayatTD.isEmpty) return Center(child: Text("Belum ada data tekanan darah", style: TextStyle(fontSize: Responsive.sp(13))));
    final chartData = _riwayatTD.reversed.toList();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20)),
      child: Container(
        padding: EdgeInsets.all(Responsive.pad(14)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(20)), boxShadow: AppTheme.shadowMd),
        child: Column(children: [
          SizedBox(
            height: Responsive.h(180),
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: Responsive.w(35), getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: Responsive.sp(9), color: AppTheme.textLight)))),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['systolic'] ?? 0).toDouble())).toList(), isCurved: true, color: AppTheme.danger, barWidth: 3, dotData: const FlDotData(show: true)),
                LineChartBarData(spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['diastolic'] ?? 0).toDouble())).toList(), isCurved: true, color: AppTheme.info, barWidth: 3, dotData: const FlDotData(show: true)),
              ],
            )),
          ),
          SizedBox(height: Responsive.h(12)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegendItem(AppTheme.danger, 'Sistolik'), SizedBox(width: Responsive.w(16)), _buildLegendItem(AppTheme.info, 'Diastolik')]),
          Divider(height: Responsive.h(24)),
          ..._riwayatTD.map((item) {
            final date = DateTime.tryParse(item['created_at'] ?? item['tgl_cek'] ?? '');
            final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '-';
            return Padding(padding: EdgeInsets.only(bottom: Responsive.h(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(dateStr, style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textMedium)),
              Text('${item['systolic']}/${item['diastolic']} mmHg', style: TextStyle(fontSize: Responsive.sp(13), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.pad(8), vertical: Responsive.pad(3)),
                decoration: BoxDecoration(color: _getKategoriColor(item['kategori'] ?? '').withAlpha(30), borderRadius: BorderRadius.circular(Responsive.radius(6))),
                child: Text(_formatKategori(item['kategori'] ?? '-'), style: TextStyle(fontSize: Responsive.sp(9), fontWeight: FontWeight.w700, color: _getKategoriColor(item['kategori'] ?? ''))),
              ),
            ]));
          }),
        ]),
      ),
    );
  }

  Widget _buildGADHistory() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_riwayatGAD.isEmpty) return Center(child: Text("Belum ada data GAD-7", style: TextStyle(fontSize: Responsive.sp(13))));
    final chartData = _riwayatGAD.reversed.toList();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20)),
      child: Container(
        padding: EdgeInsets.all(Responsive.pad(14)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(20)), boxShadow: AppTheme.shadowMd),
        child: Column(children: [
          SizedBox(
            height: Responsive.h(180),
            child: BarChart(BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: Responsive.w(30), getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: Responsive.sp(9), color: AppTheme.textLight)))),
              ),
              borderData: FlBorderData(show: false),
              barGroups: chartData.asMap().entries.map((e) {
                final skor = (e.value['skor'] ?? e.value['total_skor'] ?? 0).toDouble();
                return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: skor, color: AppTheme.primary, width: Responsive.w(14), borderRadius: BorderRadius.circular(4))]);
              }).toList(),
            )),
          ),
          SizedBox(height: Responsive.h(12)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegendItem(AppTheme.primary, 'Skor GAD-7')]),
          Divider(height: Responsive.h(24)),
          ..._riwayatGAD.map((item) {
            final date = DateTime.tryParse(item['created_at'] ?? item['tgl_gad'] ?? '');
            final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '-';
            final skor = item['skor'] ?? item['total_skor'] ?? 0;
            return Padding(padding: EdgeInsets.only(bottom: Responsive.h(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(dateStr, style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textMedium)),
              Text('Skor: $skor', style: TextStyle(fontSize: Responsive.sp(13), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.pad(8), vertical: Responsive.pad(3)),
                decoration: BoxDecoration(color: _getGADColor(item['kategori'] ?? '').withAlpha(30), borderRadius: BorderRadius.circular(Responsive.radius(6))),
                child: Text(_formatKategori(item['kategori'] ?? '-'), style: TextStyle(fontSize: Responsive.sp(9), fontWeight: FontWeight.w700, color: _getGADColor(item['kategori'] ?? ''))),
              ),
            ]));
          }),
        ]),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [
      Container(width: Responsive.w(12), height: Responsive.w(12), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: Responsive.w(6)),
      Text(text, style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textMedium)),
    ]);
  }

  String _formatKategori(String k) {
    switch (k.toLowerCase()) {
      case 'normal': return 'Normal';
      case 'pre_hipertensi': return 'Pra-Hipertensi';
      case 'hipertensi': return 'Hipertensi';
      case 'hipertensi_berat': return 'Hipertensi Berat';
      case 'ringan': return 'Ringan';
      case 'sedang': return 'Sedang';
      case 'berat': return 'Berat';
      case 'sangat_berat': return 'Sangat Berat';
      default: return k;
    }
  }

  Color _getKategoriColor(String k) {
    switch (k.toLowerCase()) {
      case 'normal': return AppTheme.success;
      case 'pre_hipertensi': return AppTheme.warning;
      case 'hipertensi': return AppTheme.danger;
      case 'hipertensi_berat': return const Color(0xFF880E4F);
      default: return AppTheme.textLight;
    }
  }

  Color _getGADColor(String k) {
    switch (k.toLowerCase()) {
      case 'ringan': return AppTheme.success;
      case 'sedang': return AppTheme.warning;
      case 'berat': return AppTheme.danger;
      case 'sangat_berat': return const Color(0xFF880E4F);
      default: return AppTheme.textLight;
    }
  }
}
