import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'chat_detail_page.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _admins = [];
  List<dynamic> _kaders = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      _admins = await _api.getAdmins();
      _kaders = await _api.getKaders();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _startChat(int receiverId, String name, String role) async {
    try {
      final result = await _api.startConversation(receiverId);
      if (result['success'] == true && mounted) {
        final convId = result['data']['id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(
            conversationId: convId, partnerName: name, partnerRole: role,
          )),
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kontak'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_admins.isNotEmpty) ...[
                    _sectionTitle('Admin'),
                    ..._admins.map((a) => _contactTile(a, 'admin')),
                    const SizedBox(height: 20),
                  ],
                  if (_kaders.isNotEmpty) ...[
                    _sectionTitle('Kader'),
                    ..._kaders.map((k) => _contactTile(k, 'kader')),
                  ],
                  if (_admins.isEmpty && _kaders.isEmpty)
                    const EmptyState(icon: Icons.people_outline, title: 'Tidak ada kontak'),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
    );
  }

  Widget _contactTile(Map<String, dynamic> user, String role) {
    final name = user['nama_lengkap'] ?? 'Unknown';
    return GestureDetector(
      onTap: () => _startChat(user['id'], name, role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.shadowSm,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: role == 'admin' ? AppTheme.warmGradient : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            Text(role.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: role == 'admin' ? AppTheme.accentWarm : AppTheme.primary)),
          ])),
          const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primarySoft, size: 22),
        ]),
      ),
    );
  }
}
