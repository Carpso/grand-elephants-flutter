import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  bool enabled;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'enabled': enabled,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );
}

class ConfigProvider extends ChangeNotifier {
  final String tenantId = 'grand-elephants-default';
  String _appName = 'Grand Elephants';
  String _appSlogan = 'Move With Conviction';
  String _appDescription =
      'Premium bags marketplace — handcrafted heritage bags, carried with conviction.';
  String _appLogo = '';

  String _currency = 'ZMW';
  String _theme = 'light';
  final double _exchangeRate = 0.036;

  List<Category> _categories = [];
  List<Map<String, dynamic>> _homeBanners = [];

  double _taxRate = 16.0;
  bool _maintenanceMode = false;

  String get appName => _appName;
  String get appSlogan => _appSlogan;
  String get appDescription => _appDescription;
  String get appLogo => _appLogo;
  String get currency => _currency;
  String get theme => _theme;
  double get exchangeRate => _exchangeRate;
  List<Category> get categories => _categories;
  double get taxRate => _taxRate;
  bool get maintenanceMode => _maintenanceMode;
  List<Map<String, dynamic>> get homeBanners => _homeBanners;

  ConfigProvider() {
    _loadLocal();
    _loadFromApi();
  }

  Future<void> _loadLocal() async {
    try {
      final saved = await StorageService.get<Map<String, dynamic>>('appBranding');
      if (saved != null) {
        if (saved['name'] != null) _appName = saved['name'] as String;
        if (saved['slogan'] != null) _appSlogan = saved['slogan'] as String;
        if (saved['description'] != null) _appDescription = saved['description'] as String;
        if (saved['logo'] != null) _appLogo = saved['logo'] as String;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Config local load error: $e');
    }
  }

  Future<void> _loadFromApi() async {
    try {
      final res = await ApiClient.instance.get('/api/config', withAuth: false);
      final cfg = res as Map<String, dynamic>;
      _appName = cfg['appName'] as String? ?? _appName;
      _appSlogan = cfg['appSlogan'] as String? ?? _appSlogan;
      _appLogo = cfg['appLogo'] as String? ?? _appLogo;
      _categories = (cfg['categories'] as List? ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      _homeBanners = (cfg['banners'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _taxRate = double.tryParse(
              (cfg['feeInfo'] as Map<String, dynamic>?)?['vatPct']?.toString() ?? '') ??
          _taxRate;
      notifyListeners();
    } catch (e) {
      debugPrint('Config api fetch error: $e');
    }
  }

  Future<void> updateAppIdentity(String name, String slogan, String description, String logo) async {
    _appName = name;
    _appSlogan = slogan;
    _appDescription = description;
    _appLogo = logo;
    await StorageService.save('appBranding', {
      'name': name,
      'slogan': slogan,
      'description': description,
      'logo': logo,
    });
    notifyListeners();
    try {
      await ApiClient.instance.patch('/api/admin/settings', body: {
        'app_name': name,
        'app_slogan': slogan,
        'app_logo': logo,
      });
    } catch (e) {
      debugPrint('Settings save to API failed: $e');
    }
  }

  void toggleCurrency() {
    _currency = _currency == 'ZMW' ? 'USD' : 'ZMW';
    notifyListeners();
  }

  void toggleTheme() {
    _theme = _theme == 'light' ? 'dark' : 'light';
    notifyListeners();
  }

  String formatPrice(double amountInZmw) {
    if (_currency == 'ZMW') {
      return 'K ${amountInZmw.toStringAsFixed(2)}';
    } else {
      return '\$ ${(amountInZmw * _exchangeRate).toStringAsFixed(2)}';
    }
  }

  void addCategory(String name, String icon) {
    _categories.add(Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
    ));
    notifyListeners();
  }

  void toggleMaintenanceMode() {
    _maintenanceMode = !_maintenanceMode;
    notifyListeners();
  }

  void addBanner(Map<String, dynamic> banner) {
    _homeBanners.add({
      ...banner,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    notifyListeners();
  }

  void removeBanner(String id) {
    _homeBanners.removeWhere((b) => b['id'] == id);
    notifyListeners();
  }

  void setAppName(String name) {
    _appName = name;
    notifyListeners();
  }

  void setAppSlogan(String slogan) {
    _appSlogan = slogan;
    notifyListeners();
  }

  void setAppDescription(String desc) {
    _appDescription = desc;
    notifyListeners();
  }

  void setCategories(List<Category> cats) {
    _categories = cats;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }
}
