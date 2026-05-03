import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'tekanan_darah_page.dart';
import 'gad7_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
        final data = jadwalStatus['data'];
        if (data != null) {
          _harusIsiTD = data['td']?['is_waiting'] == false;
          _harusIsiGAD = data['gad7']?['is_waiting'] == false;
        }
      } catch (_) {}

      try {
        final tdList = await _api.getRiwayatTD();
        _riwayatTD = tdList.take(7).toList();
      } catch (_) {}

      try {
        final gadList = await _api.getRiwayatGAD();
        _riwayatGAD = gadList.take(7).toList();
      } catch (_) {}

    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      if (!_hasShownModal && (_harusIsiTD || _harusIsiGAD)) {
        _hasShownModal = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showReminderModal();
        });
      }
    }
  }

  void _showReminderModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppTheme.warning, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pengingat Kesehatan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              const Text(
                'Anda memiliki jadwal pengisian data kesehatan yang belum diselesaikan. Silakan isi sekarang agar kondisi Anda tetap terpantau.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 24),
              if (_harusIsiTD)
                _modalButton(Icons.bloodtype_rounded, 'Isi Tekanan Darah', AppTheme.danger, () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TekananDarahPage()));
                }),
              if (_harusIsiTD && _harusIsiGAD) const SizedBox(height: 12),
              if (_harusIsiGAD)
                _modalButton(Icons.psychology_rounded, 'Isi Kuesioner GAD-7', AppTheme.info, () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GAD7Page()));
                }),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nanti Saja', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['nama_lengkap'] ?? 'Pengguna';
    final firstName = name.split(' ').first;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(firstName, name),
            const SizedBox(height: 20),

            // Reminder cards
            if (_harusIsiTD || _harusIsiGAD) ...[
              _sectionTitle('⏰ Pengingat'),
              if (_harusIsiTD) _buildReminderCard(
                'Tekanan Darah',
                'Saatnya mengisi data tekanan darah Anda',
                Icons.bloodtype_rounded,
                AppTheme.danger,
              ),
              if (_harusIsiGAD) _buildReminderCard(
                'Kuesioner GAD-7',
                'Saatnya mengisi kuesioner kesehatan mental',
                Icons.psychology_rounded,
                AppTheme.info,
              ),
              const SizedBox(height: 16),
            ],

            _sectionTitle('📊 Status Kesehatan'),
            _buildHealthStatusCards(),

            const SizedBox(height: 24),

            _sectionTitle('⚡ Aksi Cepat'),
            _buildQuickActions(),

            const SizedBox(height: 32),

            _sectionTitle('📈 Riwayat Tekanan Darah (7 Terakhir)'),
            _buildTDHistory(),

            const SizedBox(height: 32),

            _sectionTitle('📈 Riwayat GAD-7 (7 Terakhir)'),
            _buildGADHistory(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName, String fullName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $firstName! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pantau kesehatan Anda hari ini',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(String title, String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCards() {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(30),
        child: CircularProgressIndicator(color: AppTheme.primary),
      ));
    }

    final tekananDarah = _statusKesehatan?['tekanan_darah'] ?? '-/-';
    final kategoriTD = _statusKesehatan?['kategori_td'] ?? '-';
    final skorGAD = _statusKesehatan?['skor_gad']?.toString() ?? '-';
    final kategoriGAD = _statusKesehatan?['kategori_gad'] ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatusCard(
            'Tekanan Darah',
            tekananDarah.toString(),
            _formatKategori(kategoriTD.toString()),
            Icons.bloodtype_rounded,
            _getKategoriColor(kategoriTD.toString()),
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildStatusCard(
            'GAD-7',
            'Skor: $skorGAD',
            _formatKategori(kategoriGAD.toString()),
            Icons.psychology_rounded,
            _getGADColor(kategoriGAD.toString()),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, String category, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildActionItem(Icons.bloodtype_rounded, 'Tensi', AppTheme.danger),
          _buildActionItem(Icons.psychology_rounded, 'GAD-7', AppTheme.info),
          _buildActionItem(Icons.chat_bubble_rounded, 'Chat', AppTheme.accent),
          _buildActionItem(Icons.school_rounded, 'Edukasi', AppTheme.accentWarm),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withAlpha(40), color.withAlpha(12)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTDHistory() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_riwayatTD.isEmpty) return const Center(child: Text("Belum ada data tekanan darah"));

    // Sort chronologically for chart (oldest to newest)
    final chartData = _riwayatTD.reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.shadowMd,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['systolic'] ?? 0).toDouble())).toList(),
                      isCurved: true,
                      color: AppTheme.danger,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['diastolic'] ?? 0).toDouble())).toList(),
                      isCurved: true,
                      color: AppTheme.info,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTheme.danger, 'Sistolik'),
                const SizedBox(width: 16),
                _buildLegendItem(AppTheme.info, 'Diastolik'),
              ],
            ),
            const Divider(height: 32),
            ..._riwayatTD.map((item) {
              final date = DateTime.tryParse(item['created_at'] ?? item['tgl_cek'] ?? '');
              final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                    Text('${item['systolic']}/${item['diastolic']} mmHg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getKategoriColor(item['kategori'] ?? '').withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatKategori(item['kategori'] ?? '-'),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _getKategoriColor(item['kategori'] ?? '')),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGADHistory() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_riwayatGAD.isEmpty) return const Center(child: Text("Belum ada data GAD-7"));

    final chartData = _riwayatGAD.reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.shadowMd,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: chartData.asMap().entries.map((e) {
                    final skor = (e.value['skor'] ?? e.value['total_skor'] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: skor,
                          color: AppTheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTheme.primary, 'Skor GAD-7'),
              ],
            ),
            const Divider(height: 32),
            ..._riwayatGAD.map((item) {
              final date = DateTime.tryParse(item['created_at'] ?? item['tgl_gad'] ?? '');
              final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '-';
              final skor = item['skor'] ?? item['total_skor'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                    Text('Skor: $skor', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getGADColor(item['kategori'] ?? '').withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatKategori(item['kategori'] ?? '-'),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _getGADColor(item['kategori'] ?? '')),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
      ],
    );
  }

  String _formatKategori(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'normal': return 'Normal';
      case 'pre_hipertensi': return 'Pra-Hipertensi';
      case 'hipertensi': return 'Hipertensi';
      case 'hipertensi_berat': return 'Hipertensi Berat';
      case 'ringan': return 'Ringan';
      case 'sedang': return 'Sedang';
      case 'berat': return 'Berat';
      case 'sangat_berat': return 'Sangat Berat';
      default: return kategori;
    }
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'normal': return AppTheme.success;
      case 'pre_hipertensi': return AppTheme.warning;
      case 'hipertensi': return AppTheme.danger;
      case 'hipertensi_berat': return const Color(0xFF880E4F);
      default: return AppTheme.textLight;
    }
  }

  Color _getGADColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'ringan': return AppTheme.success;
      case 'sedang': return AppTheme.warning;
      case 'berat': return AppTheme.danger;
      case 'sangat_berat': return const Color(0xFF880E4F);
      default: return AppTheme.textLight;
    }
  }
}
