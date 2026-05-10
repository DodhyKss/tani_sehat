import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
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
  void initState() {
    super.initState();
    _loadInbox();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadInboxBackground();
    });
  }

  Future<void> _loadInboxBackground() async {
    try {
      final data = await _api.getInbox();
      if (mounted) {
        setState(() {
          _conversations = data;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadInbox() async {
    setState(() => _isLoading = true);
    try {
      _conversations = await _api.getInbox();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Chat',
            subtitle: 'Konsultasi dengan Kader & Admin',
            trailing: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactListPage()));
                _loadInbox();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _conversations.isEmpty
                    ? const EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Belum ada percakapan',
                        subtitle: 'Mulai chat baru dengan Kader atau Admin',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInbox,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _conversations.length,
                          itemBuilder: (_, i) => _buildChatTile(_conversations[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> conv) {
    final partner = conv['partner'] ?? {};
    final name = partner['nama_lengkap'] ?? 'Unknown';
    final role = partner['role'] ?? '';
    final latest = conv['latest_detail'];
    final lastMsg = latest?['message'] ?? '';
    final unread = conv['unread_count'] ?? 0;
    final dateStr = latest?['created_at'];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    String timeText = '';
    if (date != null) {
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) {
        timeText = '${date.day}/${date.month}';
      } else if (diff.inHours > 0) {
        timeText = '${diff.inHours}j lalu';
      } else if (diff.inMinutes > 0) {
        timeText = '${diff.inMinutes}m lalu';
      } else {
        timeText = 'Baru saja';
      }
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(
            conversationId: conv['id'],
            partnerName: name,
            partnerRole: role,
          )),
        );
        _loadInbox();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread > 0 ? AppTheme.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: role == 'admin' ? AppTheme.warmGradient : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              )),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(name,
                    style: TextStyle(fontSize: 15, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600, color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis)),
                  Text(timeText, style: TextStyle(fontSize: 11, color: unread > 0 ? AppTheme.primary : AppTheme.textLight)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: role == 'admin' ? AppTheme.accentWarm.withOpacity(0.15) : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(role.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: role == 'admin' ? AppTheme.accentWarm : AppTheme.primary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(lastMsg,
                    style: TextStyle(fontSize: 13, color: unread > 0 ? AppTheme.textDark : AppTheme.textLight,
                      fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400),
                    overflow: TextOverflow.ellipsis, maxLines: 1)),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
