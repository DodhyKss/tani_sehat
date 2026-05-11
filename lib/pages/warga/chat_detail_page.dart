import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

class ChatDetailPage extends StatefulWidget {
  final int conversationId;
  final String partnerName;
  final String partnerRole;
  const ChatDetailPage({super.key, required this.conversationId, required this.partnerName, required this.partnerRole});
  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _api = ApiService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isLoading = true, _isSending = false;
  List<dynamic> _messages = [];
  Timer? _timer;

  @override
  void initState() { super.initState(); _loadMessages(); _startTimer(); }
  @override
  void dispose() { _timer?.cancel(); _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }
  void _startTimer() { _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessagesBackground()); }

  Future<void> _loadMessagesBackground() async {
    try { final result = await _api.getConversationDetail(widget.conversationId);
      if (result['success'] == true) { final newMessages = result['data']['details'] ?? [];
        if (newMessages.length != _messages.length && mounted) { setState(() => _messages = newMessages); _scrollToBottom(); } }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try { final result = await _api.getConversationDetail(widget.conversationId);
      if (result['success'] == true) _messages = result['data']['details'] ?? []; } catch (_) {}
    if (mounted) { setState(() => _isLoading = false); _scrollToBottom(); }
  }

  void _scrollToBottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim(); if (msg.isEmpty) return; _msgCtrl.clear();
    setState(() => _isSending = true);
    try { final result = await _api.sendMessage(widget.conversationId, msg);
      if (result['success'] == true) _loadMessages(); else { if (mounted) AppToast.error(context, result['message'] ?? 'Gagal mengirim'); }
    } catch (e) { if (mounted) AppToast.error(context, '$e'); }
    finally { if (mounted) setState(() => _isSending = false); }
  }

  Future<void> _deleteMessage(int msgId) async {
    try { final result = await _api.deleteMessage(msgId); if (result['success'] == true) { AppToast.success(context, 'Pesan dihapus'); _loadMessages(); } }
    catch (e) { if (mounted) AppToast.error(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final myId = _api.userId;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.partnerName, style: TextStyle(fontSize: Responsive.sp(15), fontWeight: FontWeight.w700)),
          Text(widget.partnerRole.toUpperCase(), style: TextStyle(fontSize: Responsive.sp(10), fontWeight: FontWeight.w600, color: AppTheme.primarySoft)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadMessages)],
      ),
      body: Column(children: [
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _messages.isEmpty ? const EmptyState(icon: Icons.chat_bubble_outline, title: 'Mulai percakapan')
            : ListView.builder(controller: _scrollCtrl, padding: EdgeInsets.symmetric(horizontal: Responsive.pad(16), vertical: Responsive.pad(12)),
                itemCount: _messages.length, itemBuilder: (_, i) { final msg = _messages[i]; return _buildBubble(msg, msg['sender_id'] == myId); })),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    final date = DateTime.tryParse(msg['created_at'] ?? '');
    final timeStr = date != null ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () { showModalBottomSheet(context: context, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(20)))),
          builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.delete_outline, color: AppTheme.danger), title: const Text('Hapus Pesan'), onTap: () { Navigator.pop(ctx); _deleteMessage(msg['id']); }),
          ]))); } : null,
        child: Container(
          margin: EdgeInsets.only(bottom: Responsive.h(8)),
          padding: EdgeInsets.symmetric(horizontal: Responsive.pad(14), vertical: Responsive.pad(10)),
          constraints: BoxConstraints(maxWidth: Responsive.screenWidth * 0.75),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(Responsive.radius(18)), topRight: Radius.circular(Responsive.radius(18)),
              bottomLeft: Radius.circular(isMe ? Responsive.radius(18) : Responsive.radius(4)), bottomRight: Radius.circular(isMe ? Responsive.radius(4) : Responsive.radius(18))),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(msg['message'] ?? '', style: TextStyle(fontSize: Responsive.sp(13), color: isMe ? Colors.white : AppTheme.textDark)),
            SizedBox(height: Responsive.h(4)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(timeStr, style: TextStyle(fontSize: Responsive.sp(9), color: isMe ? Colors.white70 : AppTheme.textLight)),
              if (isMe && msg['is_read'] == true) ...[SizedBox(width: Responsive.w(4)), Icon(Icons.done_all, size: Responsive.icon(14), color: Colors.white.withOpacity(0.8))],
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(Responsive.pad(16), Responsive.pad(8), Responsive.pad(8), MediaQuery.of(context).padding.bottom + Responsive.pad(8)),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(children: [
        Expanded(child: Container(decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(Responsive.radius(24))),
          child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: 'Ketik pesan...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: Responsive.pad(18), vertical: Responsive.pad(10))),
            maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _send()))),
        SizedBox(width: Responsive.w(8)),
        GestureDetector(onTap: _isSending ? null : _send,
          child: Container(padding: EdgeInsets.all(Responsive.pad(12)), decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(Responsive.radius(14))),
            child: _isSending ? SizedBox(width: Responsive.w(20), height: Responsive.w(20), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(Icons.send_rounded, color: Colors.white, size: Responsive.icon(20)))),
      ]),
    );
  }
}
