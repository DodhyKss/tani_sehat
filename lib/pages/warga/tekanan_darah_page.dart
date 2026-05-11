import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

class TekananDarahPage extends StatefulWidget {
  const TekananDarahPage({super.key});
  @override
  State<TekananDarahPage> createState() => _TekananDarahPageState();
}

class _TekananDarahPageState extends State<TekananDarahPage> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  bool _isSaving = false, _isLoadingHistory = true, _isWaiting = false;
  String? _nextCek;
  List<dynamic> _history = [];

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); _checkSchedule(); _loadHistory(); }
  @override
  void dispose() { _tabController.dispose(); _systolicCtrl.dispose(); _diastolicCtrl.dispose(); super.dispose(); }

  Future<void> _checkSchedule() async {
    try { final res = await _api.cekJadwal('td'); if (res['success'] == true) setState(() { _isWaiting = res['data']?['td']?['is_waiting'] ?? false; _nextCek = res['data']?['td']?['next_cek']; }); } catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try { _history = await _api.getRiwayatTD(); } catch (_) {}
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  Future<void> _save() async {
    final sys = int.tryParse(_systolicCtrl.text.trim()); final dia = int.tryParse(_diastolicCtrl.text.trim());
    if (sys == null || dia == null) { AppToast.error(context, 'Masukkan nilai yang valid'); return; }
    setState(() => _isSaving = true);
    try {
      final result = await _api.storeTekananDarah(sys, dia);
      if (mounted) { if (result['success'] == true) { _systolicCtrl.clear(); _diastolicCtrl.clear(); _loadHistory(); _showResultModal(result['data']); } else AppToast.error(context, result['message'] ?? 'Gagal menyimpan'); }
    } catch (e) { if (mounted) AppToast.error(context, '$e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(body: Column(children: [
      const GradientHeader(title: 'Tekanan Darah', subtitle: 'Pantau kondisi jantung dan pembuluh darah', showBackButton: true),
      Container(color: Colors.white, child: TabBar(controller: _tabController, labelColor: AppTheme.primary, unselectedLabelColor: AppTheme.textLight, indicatorColor: AppTheme.primary, tabs: const [Tab(text: 'Input'), Tab(text: 'Riwayat')])),
      Expanded(child: TabBarView(controller: _tabController, children: [_buildInputTab(), _buildHistoryTab()])),
    ]));
  }

  Widget _buildInputTab() {
    if (_isWaiting) {
      return Center(child: Padding(padding: EdgeInsets.all(Responsive.pad(32)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: EdgeInsets.all(Responsive.pad(24)), decoration: BoxDecoration(color: AppTheme.accentWarm.withAlpha(20), shape: BoxShape.circle), child: Icon(Icons.timer_rounded, color: AppTheme.accentWarm, size: Responsive.icon(56))),
        SizedBox(height: Responsive.h(24)),
        Text('Belum Waktunya Mengisi', style: TextStyle(fontSize: Responsive.sp(18), fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        SizedBox(height: Responsive.h(12)),
        Text('Anda sudah melakukan pengisian untuk jadwal ini.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMedium, fontSize: Responsive.sp(13), height: 1.5)),
        SizedBox(height: Responsive.h(24)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: Responsive.pad(20), vertical: Responsive.pad(12)),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(Responsive.radius(12)), border: Border.all(color: AppTheme.primary.withAlpha(30))),
          child: Column(children: [
            Text('Jadwal Pengisian Berikutnya:', style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textLight)),
            SizedBox(height: Responsive.h(4)),
            Text(_nextCek ?? 'Segera', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: Responsive.sp(15))),
          ]),
        ),
      ])));
    }
    return SingleChildScrollView(padding: EdgeInsets.all(Responsive.pad(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: EdgeInsets.all(Responsive.pad(18)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(20)), boxShadow: AppTheme.shadowMd),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(Responsive.pad(10)), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(12))), child: Icon(Icons.bloodtype_rounded, color: AppTheme.danger, size: Responsive.icon(22))),
            SizedBox(width: Responsive.w(12)),
            Text('Input Tekanan Darah', style: TextStyle(fontSize: Responsive.sp(16), fontWeight: FontWeight.w700)),
          ]),
          SizedBox(height: Responsive.h(20)),
          Row(children: [
            Expanded(child: _inputField(_systolicCtrl, 'Sistolik')),
            Padding(padding: EdgeInsets.symmetric(horizontal: Responsive.pad(10)), child: Text('/', style: TextStyle(fontSize: Responsive.sp(26), fontWeight: FontWeight.w300, color: AppTheme.textLight))),
            Expanded(child: _inputField(_diastolicCtrl, 'Diastolik')),
          ]),
          SizedBox(height: Responsive.h(20)),
          SizedBox(width: double.infinity, height: Responsive.h(48), child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(14)))),
            child: _isSaving ? SizedBox(width: Responsive.w(22), height: Responsive.w(22), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Simpan', style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w600, color: Colors.white)),
          )),
        ]),
      ),
      SizedBox(height: Responsive.h(20)),
      _buildInfoCard(),
    ]));
  }

  Widget _inputField(TextEditingController ctrl, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: Responsive.sp(12), fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
      SizedBox(height: Responsive.h(8)),
      TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
        style: TextStyle(fontSize: Responsive.sp(22), fontWeight: FontWeight.w700, color: AppTheme.textDark),
        decoration: InputDecoration(filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.radius(12)), borderSide: BorderSide.none))),
    ]);
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(Responsive.pad(14)),
      decoration: BoxDecoration(color: AppTheme.info.withAlpha(20), borderRadius: BorderRadius.circular(Responsive.radius(16)), border: Border.all(color: AppTheme.info.withAlpha(50))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💡 Panduan Kategori', style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.sp(13))),
        SizedBox(height: Responsive.h(8)),
        Text('• Normal: < 120/80', style: TextStyle(fontSize: Responsive.sp(12))),
        Text('• Pra-Hipertensi: 120-139 / 80-89', style: TextStyle(fontSize: Responsive.sp(12))),
        Text('• Hipertensi: ≥ 140 / ≥ 90', style: TextStyle(fontSize: Responsive.sp(12))),
      ]),
    );
  }

  void _showResultModal(Map<String, dynamic> data) {
    final sys = data['tekanan_darah']?['systolic'] ?? '-';
    final dia = data['tekanan_darah']?['diastolic'] ?? '-';
    final kategori = data['kategori'] ?? data['kategori_td'] ?? 'Normal';
    final rekomendasi = data['rekomendasi'] ?? {};
    final materi = (rekomendasi['materi'] as List?) ?? [];
    final video = (rekomendasi['video'] as List?) ?? [];
    final gambar = (rekomendasi['gambar'] as List?) ?? [];
    final olahraga = (rekomendasi['olahraga'] as List?) ?? [];

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(24))),
      child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(Responsive.pad(20)), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.success, size: Responsive.icon(44)),
        SizedBox(height: Responsive.h(14)),
        Text('Berhasil Disimpan!', style: TextStyle(fontSize: Responsive.sp(18), fontWeight: FontWeight.w800)),
        SizedBox(height: Responsive.h(8)),
        Text('Tekanan Darah: $sys/$dia mmHg', style: TextStyle(fontSize: Responsive.sp(14))),
        Container(margin: EdgeInsets.symmetric(vertical: Responsive.h(12)), padding: EdgeInsets.symmetric(horizontal: Responsive.pad(14), vertical: Responsive.pad(8)),
          decoration: BoxDecoration(color: _getKategoriColor(kategori).withAlpha(30), borderRadius: BorderRadius.circular(Responsive.radius(12))),
          child: Text(_formatKategori(kategori), style: TextStyle(fontWeight: FontWeight.w700, color: _getKategoriColor(kategori), fontSize: Responsive.sp(13)))),
        const Divider(),
        SizedBox(height: Responsive.h(8)),
        Text('Rekomendasi Untuk Anda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.sp(15))),
        SizedBox(height: Responsive.h(12)),
        if (materi.isNotEmpty || video.isNotEmpty || gambar.isNotEmpty || olahraga.isNotEmpty) ...[
          _buildRekomList('Materi', materi, Icons.article_rounded, AppTheme.primary),
          _buildRekomList('Video', video, Icons.play_circle_fill_rounded, AppTheme.danger),
          _buildRekomList('Infografis', gambar, Icons.image_rounded, AppTheme.info),
          _buildRekomList('Olahraga', olahraga, Icons.directions_run_rounded, AppTheme.warning),
        ] else Text('Belum ada rekomendasi khusus.', style: TextStyle(color: AppTheme.textMedium, fontSize: Responsive.sp(12)), textAlign: TextAlign.center),
        SizedBox(height: Responsive.h(20)),
        SizedBox(width: double.infinity, height: Responsive.h(46), child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _tabController.animateTo(1); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(14))), elevation: 0),
          child: Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: Responsive.sp(15))))),
      ]))),
    ));
  }

  Widget _buildRekomList(String typeName, List items, IconData icon, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: Responsive.icon(18)), SizedBox(width: Responsive.w(8)), Text(typeName, style: TextStyle(fontSize: Responsive.sp(13), fontWeight: FontWeight.w700))]),
      SizedBox(height: Responsive.h(6)),
      ...items.take(1).map((item) => Padding(padding: EdgeInsets.only(left: Responsive.pad(26), bottom: Responsive.pad(4)),
        child: Text('• ${item['judul'] ?? item['nama_olahraga'] ?? 'Item'}', style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textMedium)))),
      SizedBox(height: Responsive.h(10)),
    ]);
  }

  String _formatKategori(String k) { switch (k.toLowerCase()) { case 'normal': return 'Normal'; case 'pre_hipertensi': return 'Pra-Hipertensi'; case 'hipertensi': return 'Hipertensi'; default: return k; } }
  Color _getKategoriColor(String k) { switch (k.toLowerCase()) { case 'normal': return AppTheme.success; case 'pre_hipertensi': return AppTheme.warning; case 'hipertensi': return AppTheme.danger; default: return AppTheme.primary; } }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_history.isEmpty) return const EmptyState(icon: Icons.history, title: 'Belum ada riwayat', subtitle: 'Data tekanan darah Anda akan muncul di sini');
    return RefreshIndicator(onRefresh: _loadHistory, child: ListView.builder(
      padding: EdgeInsets.all(Responsive.pad(16)), itemCount: _history.length,
      itemBuilder: (_, i) {
        final item = _history[i]; final date = DateTime.tryParse(item['created_at'] ?? '');
        return Container(
          margin: EdgeInsets.only(bottom: Responsive.h(10)),
          padding: EdgeInsets.all(Responsive.pad(14)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(14)), boxShadow: AppTheme.shadowSm),
          child: Row(children: [
            Container(padding: EdgeInsets.all(Responsive.pad(10)), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(10))), child: Icon(Icons.bloodtype_rounded, color: AppTheme.danger, size: Responsive.icon(20))),
            SizedBox(width: Responsive.w(12)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item['systolic']}/${item['diastolic']} mmHg', style: TextStyle(fontSize: Responsive.sp(16), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              if (date != null) Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textLight)),
            ])),
          ]),
        );
      },
    ));
  }
}
