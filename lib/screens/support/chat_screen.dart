import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/app_data_provider.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/widgets/toast.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  VoidCallback? _textListener;

  @override
  void initState() {
    super.initState();
    _textListener = () => setState(() {});
    _messageController.addListener(_textListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadChat();
    });
  }

  @override
  void dispose() {
    if (_textListener != null) {
      _messageController.removeListener(_textListener!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _scrollToBottom();
    try {
      await context.read<AppDataProvider>().sendChatMessage(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('Could not send message', ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appData = context.watch<AppDataProvider>();
    final userName = auth.user?.name ?? 'User';
    final messages = appData.messages;
    final initials = userName.trim().isEmpty
        ? 'U'
        : userName.trim().split(RegExp(r'\s+')).first.substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chat'),
        backgroundColor: AppColors.white,
        foregroundColor: const Color(0xFF333333),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.brandPrimary.withValues(alpha: 0.12),
            child: const Text(
              'An agent will reply shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
              ),
            ),
          ),
          Expanded(
            child: appData.loading && messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandPrimary),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            'TODAY',
                            style: TextStyle(
                              color: AppColors.brandMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (messages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Icon(Icons.forum_outlined, size: 48, color: AppColors.brandMuted),
                              const SizedBox(height: 12),
                              Text(
                                'Send us a message and we\'ll get back to you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.brandMuted),
                              ),
                            ],
                          ),
                        ),
                      ...messages.map((msg) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!msg.isUser)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.support_agent,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (!msg.isUser) const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: msg.isUser ? AppColors.brandDark : AppColors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: msg.isUser
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                        bottomRight: msg.isUser
                                            ? Radius.zero
                                            : const Radius.circular(16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.text,
                                          style: TextStyle(
                                            color: msg.isUser ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            _formatTime(msg.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: msg.isUser
                                                  ? Colors.white.withValues(alpha: 0.6)
                                                  : AppColors.brandMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (msg.isUser) const SizedBox(width: 8),
                                if (msg.isUser)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.brandPrimary,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _messageController.text.trim().isNotEmpty ? _handleSend : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _messageController.text.trim().isNotEmpty
                          ? AppColors.brandPrimary
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}