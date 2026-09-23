import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().refresh();
    });
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping;
      case 'promo':
        return Icons.local_offer;
      case 'alert':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final unread = provider.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: provider.loading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off, size: 64, color: AppColors.brandMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see order updates and promos here.',
                        style: TextStyle(color: AppColors.brandMuted),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (unread > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$unread unread',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return Semantics(
                            label: '${notif.title}. ${notif.message}. ${_formatDate(notif.createdAt)}',
                            child: GestureDetector(
                              onTap: () => provider.markRead(notif.id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: notif.read ? AppColors.white : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: notif.read ? Colors.transparent : const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: notif.read ? const Color(0xFFF3F4F6) : const Color(0xFFDBEAFE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _iconFor(notif.type),
                                        size: 24,
                                        color: notif.read ? const Color(0xFF9CA3AF) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: notif.read ? const Color(0xFF374151) : const Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDate(notif.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                              color: notif.read ? const Color(0xFF6B7280) : const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!notif.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3B82F6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}