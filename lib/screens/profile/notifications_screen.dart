import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';

class _Notification {
  final String id;
  final String title;
  final String message;
  final String date;
  bool read;
  final IconData type;

  _Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.read = false,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notification> _notifications = [
    _Notification(
      id: '1',
      title: 'Order Shipped',
      message: 'Your order #1024 is on its way!',
      date: '2 hours ago',
      read: false,
      type: Icons.local_shipping,
    ),
    _Notification(
      id: '2',
      title: 'New Arrival',
      message: 'Check out the new Royal Collection.',
      date: '1 day ago',
      read: true,
      type: Icons.new_releases,
    ),
    _Notification(
      id: '3',
      title: 'Promo',
      message: 'Get 20% off your next purchase.',
      date: '2 days ago',
      read: true,
      type: Icons.local_offer,
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        _notifications[idx].read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return GestureDetector(
            onTap: () => _markAsRead(notif.id),
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
                      notif.type,
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
                              notif.date,
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
          );
        },
      ),
    );
  }
}
