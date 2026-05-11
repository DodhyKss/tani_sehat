import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';
import 'chat_detail_page.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});
  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _admins = [], _kaders = [];

  @override
  void initState() { super.initState(); _loadContacts(); }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try { _admins = await _api.getAdmins(); _kaders = await _api.getKaders(); } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _startChat(int receiverId, String name, String role) async {
    try { final result = await _api.startConversation(receiverId);
      if (result['success'] == true && mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: result['data']['id'], partnerName: name, partnerRole: role)));
    } catch (e) { if (mounted) AppToast.error(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Kontak'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context))),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(padding: EdgeInsets.all(Responsive.pad(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_admins.isNotEmpty) ...[_sectionTitle('Admin'), ..._admins.map((a) => _contactTile(a, 'admin')), SizedBox(height: Responsive.h(20))],
              if (_kaders.isNotEmpty) ...[_sectionTitle('Kader'), ..._kaders.map((k) => _contactTile(k, 'kader'))],
              if (_admins.isEmpty && _kaders.isEmpty) const EmptyState(icon: Icons.people_outline, title: 'Tidak ada kontak'),
            ])),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: EdgeInsets.only(left: Responsive.pad(4), bottom: Responsive.pad(10)),
    child: Text(title, style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700, color: AppTheme.textDark)));

  Widget _contactTile(Map<String, dynamic> user, String role) {
    final name = user['nama_lengkap'] ?? 'Unknown';
    return GestureDetector(onTap: () => _startChat(user['id'], name, role),
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.h(8)),
        padding: EdgeInsets.all(Responsive.pad(12)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(14)), boxShadow: AppTheme.shadowSm),
        child: Row(children: [
          Container(width: Responsive.w(40), height: Responsive.w(40), decoration: BoxDecoration(gradient: role == 'admin' ? AppTheme.warmGradient : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(Responsive.radius(12))),
            child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: Responsive.sp(16), fontWeight: FontWeight.w700)))),
          SizedBox(width: Responsive.w(12)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: Responsive.sp(14), fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            Text(role.toUpperCase(), style: TextStyle(fontSize: Responsive.sp(10), fontWeight: FontWeight.w600, color: role == 'admin' ? AppTheme.accentWarm : AppTheme.primary)),
          ])),
          Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primarySoft, size: Responsive.icon(20)),
        ]),
      ),
    );
  }
}
