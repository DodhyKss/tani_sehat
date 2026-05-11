import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';
import 'chat_detail_page.dart';
import 'contact_list_page.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});
  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _conversations = [];
  Timer? _timer;

  @override
  void initState() { super.initState(); _loadInbox(); _startTimer(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  void _startTimer() { _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadInboxBackground()); }

  Future<void> _loadInboxBackground() async { try { final data = await _api.getInbox(); if (mounted) setState(() => _conversations = data); } catch (_) {} }
  Future<void> _loadInbox() async { setState(() => _isLoading = true); try { _conversations = await _api.getInbox(); } catch (_) {} if (mounted) setState(() => _isLoading = false); }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(body: Column(children: [
      GradientHeader(title: 'Chat', subtitle: 'Konsultasi dengan Kader & Admin',
        trailing: GestureDetector(
          onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactListPage())); _loadInbox(); },
          child: Container(padding: EdgeInsets.all(Responsive.pad(10)), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(Responsive.radius(12))),
            child: Icon(Icons.person_add_rounded, color: Colors.white, size: Responsive.icon(22))),
        ),
      ),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _conversations.isEmpty ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'Belum ada percakapan', subtitle: 'Mulai chat baru dengan Kader atau Admin')
          : RefreshIndicator(onRefresh: _loadInbox, child: ListView.builder(padding: EdgeInsets.symmetric(vertical: Responsive.pad(8)), itemCount: _conversations.length, itemBuilder: (_, i) => _buildChatTile(_conversations[i])))),
    ]));
  }

  Widget _buildChatTile(Map<String, dynamic> conv) {
    final partner = conv['partner'] ?? {}; final name = partner['nama_lengkap'] ?? 'Unknown'; final role = partner['role'] ?? '';
    final latest = conv['latest_detail']; final lastMsg = latest?['message'] ?? ''; final unread = conv['unread_count'] ?? 0;
    final dateStr = latest?['created_at']; final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    String timeText = '';
    if (date != null) { final diff = DateTime.now().difference(date); if (diff.inDays > 0) timeText = '${date.day}/${date.month}'; else if (diff.inHours > 0) timeText = '${diff.inHours}j lalu'; else if (diff.inMinutes > 0) timeText = '${diff.inMinutes}m lalu'; else timeText = 'Baru saja'; }

    return GestureDetector(
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(conversationId: conv['id'], partnerName: name, partnerRole: role))); _loadInbox(); },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: Responsive.pad(16), vertical: Responsive.pad(4)),
        padding: EdgeInsets.all(Responsive.pad(12)),
        decoration: BoxDecoration(color: unread > 0 ? AppTheme.primary.withOpacity(0.04) : Colors.white, borderRadius: BorderRadius.circular(Responsive.radius(16)), boxShadow: AppTheme.shadowSm),
        child: Row(children: [
          Container(width: Responsive.w(46), height: Responsive.w(46), decoration: BoxDecoration(gradient: role == 'admin' ? AppTheme.warmGradient : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(Responsive.radius(14))),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: Colors.white, fontSize: Responsive.sp(18), fontWeight: FontWeight.w700)))),
          SizedBox(width: Responsive.w(12)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, style: TextStyle(fontSize: Responsive.sp(14), fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600, color: AppTheme.textDark), overflow: TextOverflow.ellipsis)),
              Text(timeText, style: TextStyle(fontSize: Responsive.sp(10), color: unread > 0 ? AppTheme.primary : AppTheme.textLight)),
            ]),
            SizedBox(height: Responsive.h(4)),
            Row(children: [
              Container(padding: EdgeInsets.symmetric(horizontal: Responsive.pad(6), vertical: Responsive.pad(2)),
                decoration: BoxDecoration(color: role == 'admin' ? AppTheme.accentWarm.withOpacity(0.15) : AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(Responsive.radius(4))),
                child: Text(role.toUpperCase(), style: TextStyle(fontSize: Responsive.sp(8), fontWeight: FontWeight.w700, color: role == 'admin' ? AppTheme.accentWarm : AppTheme.primary))),
              SizedBox(width: Responsive.w(8)),
              Expanded(child: Text(lastMsg, style: TextStyle(fontSize: Responsive.sp(12), color: unread > 0 ? AppTheme.textDark : AppTheme.textLight, fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400), overflow: TextOverflow.ellipsis, maxLines: 1)),
              if (unread > 0) Container(padding: EdgeInsets.symmetric(horizontal: Responsive.pad(8), vertical: Responsive.pad(3)),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(Responsive.radius(12))),
                child: Text('$unread', style: TextStyle(color: Colors.white, fontSize: Responsive.sp(10), fontWeight: FontWeight.w700))),
            ]),
          ])),
        ]),
      ),
    );
  }
}
