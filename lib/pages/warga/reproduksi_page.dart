import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReproduksiPage extends StatefulWidget {
  const ReproduksiPage({super.key});

  @override
  State<ReproduksiPage> createState() => _ReproduksiPageState();
}

class _ReproduksiPageState extends State<ReproduksiPage> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _data = await _api.getReproduksi();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final result = await _api.deleteReproduksi(id);
        if (mounted) {
          AppToast.success(context, result['message'] ?? 'Berhasil dihapus');
          _loadData();
        }
      } catch (e) {
        if (mounted) AppToast.error(context, '$e');
      }
    }
  }

  void _showAddDialog() {
    final anakCtrl = TextEditingController();
    final kbCtrl = TextEditingController();
    final masalahCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Data Reproduksi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 20),
            TextField(
              controller: anakCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Anak', prefixIcon: Icon(Icons.child_care)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: kbCtrl,
              decoration: const InputDecoration(labelText: 'Penggunaan KB', prefixIcon: Icon(Icons.medical_services_outlined)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: masalahCtrl,
              decoration: const InputDecoration(labelText: 'Masalah Reproduksi', prefixIcon: Icon(Icons.note_alt_outlined)),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final anak = int.tryParse(anakCtrl.text.trim());
                  if (anak == null) {
                    AppToast.error(context, 'Jumlah anak harus angka');
                    return;
                  }
                  try {
                    final result = await _api.storeReproduksi(
                      jumlahAnak: anak,
                      penggunaanKb: kbCtrl.text.trim(),
                      masalahReproduksi: masalahCtrl.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      AppToast.success(context, result['message'] ?? 'Berhasil disimpan');
                      _loadData();
                    }
                  } catch (e) {
                    if (mounted) AppToast.error(context, '$e');
                  }
                },
                child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Reproduksi'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _data.isEmpty
              ? const EmptyState(icon: Icons.pregnant_woman_rounded, title: 'Belum ada data', subtitle: 'Tambahkan data reproduksi Anda')
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _data.length,
                    itemBuilder: (_, i) {
                      final item = _data[i];
                      final date = DateTime.tryParse(item['created_at'] ?? '');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFAB47BC).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.pregnant_woman_rounded, color: Color(0xFFAB47BC), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Jumlah Anak: ${item['jumlah_anak']}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                if (date != null)
                                  Text('${date.day}/${date.month}/${date.year}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                              ])),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
                                onPressed: () => _delete(item['id']),
                              ),
                            ]),
                            const Divider(height: 20),
                            _infoRow('KB', item['penggunaan_kb'] ?? '-'),
                            const SizedBox(height: 6),
                            _infoRow('Masalah', item['masalah_reproduksi'] ?? '-'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textDark))),
    ]);
  }
}
