import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: json['type'] as String? ?? 'info',
        read: json['read'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class NotificationSettings {
  bool stockAlerts;
  bool orderUpdates;
  bool promotions;

  NotificationSettings({
    this.stockAlerts = false,
    this.orderUpdates = true,
    this.promotions = false,
  });

  NotificationSettings copyWith({
    bool? stockAlerts,
    bool? orderUpdates,
    bool? promotions,
  }) =>
      NotificationSettings(
        stockAlerts: stockAlerts ?? this.stockAlerts,
        orderUpdates: orderUpdates ?? this.orderUpdates,
        promotions: promotions ?? this.promotions,
      );
}

class NotificationProvider extends ChangeNotifier {
  String? _expoPushToken;
  List<AppNotification> _notifications = [];
  NotificationSettings _settings = NotificationSettings();
  bool _loading = false;
  String? _error;

  String? get expoPushToken => _expoPushToken;
  List<AppNotification> get notifications => _notifications;
  NotificationSettings get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  NotificationProvider() {
    _init();
  }

  void _init() {
    _load();
  }

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get('/api/notifications/mine');
      _notifications = (res as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '$e';
      debugPrint('Notifications load failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> markRead(String id) async {
    try {
      await ApiClient.instance.post('/api/notifications/$id/read', body: {});
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index >= 0) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          read: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark read failed: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.instance.post('/api/notifications/read-all', body: {});
      _notifications = _notifications
          .map((n) => AppNotification(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                read: true,
                createdAt: n.createdAt,
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Mark all read failed: $e');
    }
  }

  void updateSettings({bool? stockAlerts, bool? orderUpdates, bool? promotions}) {
    _settings = _settings.copyWith(
      stockAlerts: stockAlerts,
      orderUpdates: orderUpdates,
      promotions: promotions,
    );
    notifyListeners();
  }
}