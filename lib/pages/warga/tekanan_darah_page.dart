import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

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
  bool _isSaving = false;
  bool _isLoadingHistory = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      _history = await _api.getRiwayatTD();
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  Future<void> _save() async {
    final sys = int.tryParse(_systolicCtrl.text.trim());
    final dia = int.tryParse(_diastolicCtrl.text.trim());
    if (sys == null || dia == null) {
      AppToast.error(context, 'Masukkan nilai yang valid');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await _api.storeTekananDarah(sys, dia);
      if (mounted) {
        if (result['success'] == true) {
          _systolicCtrl.clear();
          _diastolicCtrl.clear();
          _loadHistory();
          _showResultModal(result['data']);
        } else {
          AppToast.error(context, result['message'] ?? 'Gagal menyimpan');
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tekanan Darah'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Input'), Tab(text: 'Riwayat')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInputTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bloodtype_rounded, color: AppTheme.danger),
                  ),
                  const SizedBox(width: 14),
                  const Text('Input Tekanan Darah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: _inputField(_systolicCtrl, 'Sistolik', 'mmHg')),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('/', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: AppTheme.textLight)),
                  ),
                  Expanded(child: _inputField(_diastolicCtrl, 'Diastolik', 'mmHg')),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.info.withAlpha(50)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Panduan Kategori', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(height: 8),
          Text('• Normal: < 120/80', style: TextStyle(fontSize: 13)),
          Text('• Pra-Hipertensi: 120-139 / 80-89', style: TextStyle(fontSize: 13)),
          Text('• Hipertensi: ≥ 140 / ≥ 90', style: TextStyle(fontSize: 13)),
        ],
      ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 48),
                const SizedBox(height: 16),
                const Text('Berhasil Disimpan!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Tekanan Darah: $sys/$dia mmHg', style: const TextStyle(fontSize: 16)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getKategoriColor(kategori).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatKategori(kategori),
                    style: TextStyle(fontWeight: FontWeight.w700, color: _getKategoriColor(kategori)),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Rekomendasi Untuk Anda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                if (materi.isNotEmpty || video.isNotEmpty || gambar.isNotEmpty || olahraga.isNotEmpty) ...[
                  _buildRekomList('Materi', materi, Icons.article_rounded, AppTheme.primary),
                  _buildRekomList('Video', video, Icons.play_circle_fill_rounded, AppTheme.danger),
                  _buildRekomList('Infografis', gambar, Icons.image_rounded, AppTheme.info),
                  _buildRekomList('Olahraga', olahraga, Icons.directions_run_rounded, AppTheme.warning),
                ] else
                  const Text('Belum ada rekomendasi khusus untuk kategori Anda.', style: TextStyle(color: AppTheme.textMedium, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _tabController.animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRekomList(String typeName, List items, IconData icon, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(typeName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]
        ),
        const SizedBox(height: 6),
        ...items.take(1).map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text('• ${item['judul'] ?? item['nama_olahraga'] ?? 'Item'}', style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
        )).toList(),
        const SizedBox(height: 12),
      ]
    );
  }

  String _formatKategori(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'normal': return 'Normal';
      case 'pre_hipertensi': return 'Pra-Hipertensi';
      case 'hipertensi': return 'Hipertensi';
      default: return kategori;
    }
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'normal': return AppTheme.success;
      case 'pre_hipertensi': return AppTheme.warning;
      case 'hipertensi': return AppTheme.danger;
      default: return AppTheme.primary;
    }
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_history.isEmpty) {
      return const EmptyState(icon: Icons.history, title: 'Belum ada riwayat', subtitle: 'Data tekanan darah Anda akan muncul di sini');
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final item = _history[i];
          final date = DateTime.tryParse(item['created_at'] ?? '');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.shadowSm,
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bloodtype_rounded, color: AppTheme.danger, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${item['systolic']}/${item['diastolic']} mmHg',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                if (date != null)
                  Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
