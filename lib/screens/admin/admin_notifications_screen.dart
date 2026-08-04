import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/widgets/toast.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ToastProvider.of(context).show('Please enter both a title and a message body.', ToastType.error);
      return;
    }

    setState(() => _sending = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _sending = false);
        final targetLabel = _target == 'all' ? 'All Users' : _target == 'riders' ? 'Riders' : 'Customers';
        ToastProvider.of(context).show('Message "${_titleController.text}" has been queued for $targetLabel.', ToastType.success);
        _titleController.clear();
        _bodyController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const history = [
      _NotificationHistory(id: 1, title: 'Flash Sale!', body: 'Get 20% off all bags today.', target: 'All Users', date: '2 days ago', stats: '98% Delivered'),
      _NotificationHistory(id: 2, title: 'Rider Alert', body: 'Heavy rain expected in Lusaka.', target: 'Riders', date: 'Last week', stats: '100% Delivered'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Push Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compose Message',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: ['all', 'customers', 'riders'].map((t) {
                        final isSelected = _target == t;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _target = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  t[0].toUpperCase() + t.substring(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.brandDark : AppColors.brandMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SoftInput(
                    label: 'Title',
                    controller: _titleController,
                    hint: 'e.g. Weekend Special',
                    icon: const Icon(Icons.title, size: 20, color: AppColors.brandMuted),
                  ),
                  SoftInput(
                    label: 'Message Body',
                    controller: _bodyController,
                    hint: 'Type your alert message here...',
                    maxLines: 4,
                    icon: const Icon(Icons.message, size: 20, color: AppColors.brandMuted),
                  ),
                  SoftButton(
                    title: _sending ? 'Broadcasting...' : 'Send Notification',
                    variant: SoftButtonVariant.primary,
                    icon: const Icon(Icons.send, size: 20, color: AppColors.brandDark),
                    onPressed: _sending ? null : _handleSend,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Broadcasts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
            ),
            const SizedBox(height: 16),
            ...history.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                              child: Text(item.target, style: const TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.body, style: const TextStyle(color: AppColors.brandSecondary)),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.date, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                            Row(
                              children: [
                                const Icon(Icons.done_all, size: 14, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text(item.stats, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _NotificationHistory {
  final int id;
  final String title;
  final String body;
  final String target;
  final String date;
  final String stats;

  const _NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.date,
    required this.stats,
  });
}
