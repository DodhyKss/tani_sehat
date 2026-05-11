import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

class GAD7Page extends StatefulWidget {
  const GAD7Page({super.key});
  @override
  State<GAD7Page> createState() => _GAD7PageState();
}

class _GAD7PageState extends State<GAD7Page> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  bool _isLoadingQuestions = true, _isLoadingHistory = true, _isSaving = false, _isWaiting = false;
  String? _nextCek;
  List<dynamic> _questions = [], _history = [];
  Map<int, int> _answers = {};
  final _optionLabels = ['Tidak Sama Sekali', 'Beberapa Hari', 'Lebih dari Setengah', 'Hampir Setiap Hari'];

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); _checkSchedule(); _loadQuestions(); _loadHistory(); }

  Future<void> _checkSchedule() async {
    try { final res = await _api.cekJadwal('gad7'); if (res['success'] == true) setState(() { _isWaiting = res['data']?['gad7']?['is_waiting'] ?? false; _nextCek = res['data']?['gad7']?['next_cek']; }); } catch (_) {}
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadQuestions() async { try { _questions = await _api.getKuesionerGAD(); } catch (_) {} if (mounted) setState(() => _isLoadingQuestions = false); }
  Future<void> _loadHistory() async { setState(() => _isLoadingHistory = true); try { _history = await _api.getRiwayatGAD(); } catch (_) {} if (mounted) setState(() => _isLoadingHistory = false); }
  int get _totalSkor => _answers.values.fold(0, (a, b) => a + b);

  Future<void> _submit() async {
    if (_answers.length < _questions.length) { AppToast.error(context, 'Harap jawab semua pertanyaan'); return; }
    setState(() => _isSaving = true);
    try {
      final jawabanList = _answers.entries.map((e) => {'kuesioner_id': e.key, 'skor': e.value}).toList();
      final result = await _api.storeGAD(_totalSkor, jawabanList);
      if (mounted) { if (result['success'] == true) { _answers.clear(); _loadHistory(); _showResultModal(result['data']); } else AppToast.error(context, result['message'] ?? 'Gagal'); }
    } catch (e) { if (mounted) AppToast.error(context, '$e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(body: Column(children: [
      const GradientHeader(title: 'Kuesioner GAD-7', subtitle: 'Deteksi dini tingkat kecemasan Anda', showBackButton: true),
      Container(color: Colors.white, child: TabBar(controller: _tabController, labelColor: AppTheme.primary, unselectedLabelColor: AppTheme.textLight, indicatorColor: AppTheme.primary, tabs: const [Tab(text: 'Kuesioner'), Tab(text: 'Riwayat')])),
      Expanded(child: TabBarView(controller: _tabController, children: [_buildQuestionTab(), _buildHistoryTab()])),
    ]));
  }

  Widget _buildQuestionTab() {
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
    if (_isLoadingQuestions) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_questions.isEmpty) return const EmptyState(icon: Icons.quiz, title: 'Belum ada kuesioner');

    return Column(children: [
      Container(
        margin: EdgeInsets.all(Responsive.pad(16)),
        padding: EdgeInsets.all(Responsive.pad(14)),
        decoration: BoxDecoration(color: AppTheme.info.withOpacity(0.08), borderRadius: BorderRadius.circular(Responsive.radius(16))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.psychology_rounded, color: AppTheme.info, size: Responsive.icon(22)),
          SizedBox(width: Responsive.w(10)),
          Text('Skor: $_totalSkor / ${_questions.length * 3}', style: TextStyle(fontSize: Responsive.sp(16), fontWeight: FontWeight.w700, color: AppTheme.info)),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: Responsive.pad(16)),
        itemCount: _questions.length + 1,
        itemBuilder: (_, i) {
          if (i == _questions.length) return Padding(padding: EdgeInsets.symmetric(vertical: Responsive.pad(20)),
            child: SizedBox(height: Responsive.h(48), child: ElevatedButton(onPressed: _isSaving ? null : _submit,
              child: _isSaving ? SizedBox(width: Responsive.w(22), height: Responsive.w(22), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Kirim Jawaban', style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w600, color: Colors.white)))));
          final q = _questions[i]; final qId = q['id'] as int;
          return Container(
            margin: EdgeInsets.only(bottom: Responsive.h(12)),
            padding: EdgeInsets.all(Responsive.pad(14)),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${q['soal'] ?? ''}', style: TextStyle(fontSize: Responsive.sp(13), fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              SizedBox(height: Responsive.h(10)),
              ...List.generate(4, (optIdx) {
                final selected = _answers[qId] == optIdx;
                return GestureDetector(
                  onTap: () => setState(() => _answers[qId] = optIdx),
                  child: Container(
                    margin: EdgeInsets.only(bottom: Responsive.h(5)),
                    padding: EdgeInsets.symmetric(horizontal: Responsive.pad(12), vertical: Responsive.pad(9)),
                    decoration: BoxDecoration(color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface, borderRadius: BorderRadius.circular(Responsive.radius(10)), border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 1.5)),
                    child: Row(children: [
                      Container(width: Responsive.w(22), height: Responsive.w(22), decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? AppTheme.primary : Colors.white, border: Border.all(color: selected ? AppTheme.primary : AppTheme.textLight, width: 2)),
                        child: selected ? Icon(Icons.check, size: Responsive.icon(13), color: Colors.white) : null),
                      SizedBox(width: Responsive.w(10)),
                      Expanded(child: Text('($optIdx) ${_optionLabels[optIdx]}', style: TextStyle(fontSize: Responsive.sp(12), fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppTheme.primary : AppTheme.textMedium))),
                    ]),
                  ),
                );
              }),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_history.isEmpty) return const EmptyState(icon: Icons.history, title: 'Belum ada riwayat GAD-7');
    return RefreshIndicator(onRefresh: _loadHistory, child: ListView.builder(
      padding: EdgeInsets.all(Responsive.pad(16)), itemCount: _history.length,
      itemBuilder: (_, i) {
        final item = _history[i]; final date = DateTime.tryParse(item['created_at'] ?? ''); final skor = item['skor'] ?? item['total_skor'] ?? 0;
        return Container(
          margin: EdgeInsets.only(bottom: Responsive.h(10)),
          padding: EdgeInsets.all(Responsive.pad(14)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(14)), boxShadow: AppTheme.shadowSm),
          child: Row(children: [
            Container(padding: EdgeInsets.all(Responsive.pad(10)), decoration: BoxDecoration(color: AppTheme.info.withAlpha(25), borderRadius: BorderRadius.circular(Responsive.radius(10))), child: Icon(Icons.psychology_rounded, color: AppTheme.info, size: Responsive.icon(20))),
            SizedBox(width: Responsive.w(12)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Skor: $skor', style: TextStyle(fontSize: Responsive.sp(16), fontWeight: FontWeight.w700)),
              if (date != null) Text('${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textLight)),
            ])),
          ]),
        );
      },
    ));
  }

  void _showResultModal(Map<String, dynamic> data) {
    final skor = data['gad']?['skor'] ?? data['skor_total'] ?? '-';
    final kategori = data['kategori'] ?? data['kategori_gad'] ?? 'Normal';
    final rekomendasi = data['rekomendasi'] ?? {};
    final materi = (rekomendasi['materi'] as List?) ?? [];
    final video = (rekomendasi['video'] as List?) ?? [];
    final gambar = (rekomendasi['gambar'] as List?) ?? [];
    final olahraga = (rekomendasi['olahraga'] as List?) ?? [];

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(24))),
      child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(Responsive.pad(20)), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Icon(Icons.check_circle_rounded, color: AppTheme.success, size: Responsive.icon(44))),
        SizedBox(height: Responsive.h(14)),
        Center(child: Text('Kuesioner Disimpan!', style: TextStyle(fontSize: Responsive.sp(18), fontWeight: FontWeight.w800))),
        SizedBox(height: Responsive.h(8)),
        Center(child: Text('Skor GAD-7: $skor', style: TextStyle(fontSize: Responsive.sp(14)))),
        Center(child: Container(margin: EdgeInsets.symmetric(vertical: Responsive.h(12)), padding: EdgeInsets.symmetric(horizontal: Responsive.pad(14), vertical: Responsive.pad(8)),
          decoration: BoxDecoration(color: _getGADColor(kategori).withAlpha(30), borderRadius: BorderRadius.circular(Responsive.radius(12))),
          child: Text(_formatKategori(kategori), style: TextStyle(fontWeight: FontWeight.w700, color: _getGADColor(kategori), fontSize: Responsive.sp(13))))),
        const Divider(),
        SizedBox(height: Responsive.h(8)),
        Text('Rekomendasi Untuk Anda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: Responsive.sp(15))),
        SizedBox(height: Responsive.h(12)),
        if (materi.isNotEmpty || video.isNotEmpty || gambar.isNotEmpty || olahraga.isNotEmpty) ...[
          _buildRekomList('Materi', materi, Icons.article_rounded, AppTheme.primary),
          _buildRekomList('Video', video, Icons.play_circle_fill_rounded, AppTheme.danger),
          _buildRekomList('Infografis', gambar, Icons.image_rounded, AppTheme.info),
          _buildRekomList('Olahraga', olahraga, Icons.directions_run_rounded, AppTheme.warning),
        ] else Text('Belum ada rekomendasi khusus.', style: TextStyle(color: AppTheme.textMedium, fontSize: Responsive.sp(12))),
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

  String _formatKategori(String k) { switch (k.toLowerCase()) { case 'ringan': return 'Ringan'; case 'sedang': return 'Sedang'; case 'berat': return 'Berat'; case 'sangat_berat': return 'Sangat Berat'; case 'tinggi': return 'Tinggi'; case 'normal': return 'Normal'; default: return k; } }
  Color _getGADColor(String k) { switch (k.toLowerCase()) { case 'ringan': return AppTheme.success; case 'sedang': return AppTheme.warning; case 'berat': case 'tinggi': return AppTheme.danger; case 'sangat_berat': return const Color(0xFF880E4F); case 'normal': return AppTheme.primary; default: return AppTheme.textLight; } }
}
