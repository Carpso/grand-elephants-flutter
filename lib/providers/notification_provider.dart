import 'package:flutter/foundation.dart';

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
  Map<String, dynamic>? _notification;
  NotificationSettings _settings = NotificationSettings();

  String? get expoPushToken => _expoPushToken;
  Map<String, dynamic>? get notification => _notification;
  NotificationSettings get settings => _settings;

  NotificationProvider() {
    _init();
  }

  void _init() {
    _expoPushToken = 'SIMULATED_TOKEN';
    notifyListeners();
  }

  void updateSettings({bool? stockAlerts, bool? orderUpdates, bool? promotions}) {
    _settings = _settings.copyWith(
      stockAlerts: stockAlerts,
      orderUpdates: orderUpdates,
      promotions: promotions,
    );
    notifyListeners();
  }

  Future<void> sendStockAlert() async {
    if (!_settings.stockAlerts) {
      throw Exception('Please enable Stock Alerts first!');
    }
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("New Collection Dropped! The 'Golden Savannah' collection is now live.");
  }
}
