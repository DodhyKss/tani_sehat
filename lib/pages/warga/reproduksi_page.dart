import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

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
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _data = await _api.getReproduksi(); } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Hapus Data'), content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: AppTheme.danger)))],
    ));
    if (confirm == true) { try { final result = await _api.deleteReproduksi(id); if (mounted) { AppToast.success(context, result['message'] ?? 'Berhasil dihapus'); _loadData(); } } catch (e) { if (mounted) AppToast.error(context, '$e'); } }
  }

  void _showAddDialog() {
    final tglCtrl = TextEditingController(); final ketCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(24)))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(Responsive.pad(24), Responsive.pad(24), Responsive.pad(24), MediaQuery.of(ctx).viewInsets.bottom + Responsive.pad(24)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tambah Data Reproduksi', style: TextStyle(fontSize: Responsive.sp(18), fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          SizedBox(height: Responsive.h(20)),
          TextField(controller: tglCtrl, readOnly: true, onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now(),
              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)), child: child!));
            if (date != null) tglCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          }, decoration: const InputDecoration(labelText: 'Tanggal Menstruasi', prefixIcon: Icon(Icons.calendar_today))),
          SizedBox(height: Responsive.h(14)),
          TextField(controller: ketCtrl, decoration: const InputDecoration(labelText: 'Keterangan', prefixIcon: Icon(Icons.note_alt_outlined)), maxLines: 2),
          SizedBox(height: Responsive.h(24)),
          SizedBox(width: double.infinity, height: Responsive.h(48), child: ElevatedButton(
            onPressed: () async {
              if (tglCtrl.text.trim().isEmpty || ketCtrl.text.trim().isEmpty) { AppToast.error(context, 'Tanggal dan keterangan harus diisi'); return; }
              try { final result = await _api.storeReproduksi(keterangan: ketCtrl.text.trim(), tglMenstruasi: tglCtrl.text.trim());
                if (mounted) { Navigator.pop(ctx); AppToast.success(context, result['message'] ?? 'Berhasil disimpan'); _loadData(); }
              } catch (e) { if (mounted) AppToast.error(context, '$e'); }
            },
            child: Text('Simpan', style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w600, color: Colors.white)),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: _showAddDialog, backgroundColor: AppTheme.primary,
        icon: Icon(Icons.add, color: Colors.white, size: Responsive.icon(20)),
        label: Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: Responsive.sp(13)))),
      body: Column(children: [
        const GradientHeader(title: 'Data Reproduksi', subtitle: 'Catat dan pantau riwayat haid Anda', showBackButton: true),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _data.isEmpty ? const EmptyState(icon: Icons.water_drop_rounded, title: 'Belum ada data', subtitle: 'Tambahkan data reproduksi Anda')
            : RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
                padding: EdgeInsets.all(Responsive.pad(16)), itemCount: _data.length,
                itemBuilder: (_, i) {
                  final item = _data[i]; final date = DateTime.tryParse(item['tgl_input'] ?? item['created_at'] ?? '');
                  return Container(
                    margin: EdgeInsets.only(bottom: Responsive.h(12)),
                    padding: EdgeInsets.all(Responsive.pad(16)),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: EdgeInsets.all(Responsive.pad(8)), decoration: BoxDecoration(color: const Color(0xFFAB47BC).withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(10))),
                          child: Icon(Icons.water_drop, color: const Color(0xFFAB47BC), size: Responsive.icon(18))),
                        SizedBox(width: Responsive.w(10)),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Tgl Menstruasi: ${_formatDate(item['tgl_menstruasi'])}', style: TextStyle(fontSize: Responsive.sp(14), fontWeight: FontWeight.w700)),
                          if (date != null) Text('Diinput pada: ${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: Responsive.sp(11), color: AppTheme.textLight)),
                        ])),
                        IconButton(icon: Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: Responsive.icon(20)), onPressed: () => _delete(item['id'])),
                      ]),
                      Divider(height: Responsive.h(20)),
                      _infoRow('Ket', item['keterangan'] ?? '-'),
                    ]),
                  );
                },
              ))),
      ]),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try { final date = DateTime.parse(dateStr); return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'; }
    catch (_) { return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr; }
  }

  Widget _infoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: Responsive.w(70), child: Text('$label:', style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textLight, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(fontSize: Responsive.sp(12), color: AppTheme.textDark))),
    ]);
  }
}
