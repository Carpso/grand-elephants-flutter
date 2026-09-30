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
  // Value of 1 ZMW in USD. Refreshed from GET /api/fx (live USD->ZMW rate).
  double _exchangeRate = 0.036;
  double _usdToZmw = 1 / 0.036;
  String _fxSource = '';
  DateTime? _fxUpdatedAt;
  bool _fxStale = false;

  List<Category> _categories = [];
  List<Map<String, dynamic>> _homeBanners = [];

  double _taxRate = 16.0;
  double _deliveryBaseFee = 25;
  double _deliveryPerKm = 10;
  bool _maintenanceMode = false;

  String get appName => _appName;
  String get appSlogan => _appSlogan;
  String get appDescription => _appDescription;
  String get appLogo => _appLogo;
  String get currency => _currency;
  String get theme => _theme;
  double get exchangeRate => _exchangeRate;
  double get usdToZmw => _usdToZmw;
  String get fxSource => _fxSource;
  DateTime? get fxUpdatedAt => _fxUpdatedAt;
  bool get fxStale => _fxStale;
  List<Category> get categories => _categories;
  double get taxRate => _taxRate;
  double get deliveryBaseFee => _deliveryBaseFee;
  double get deliveryPerKm => _deliveryPerKm;
  bool get maintenanceMode => _maintenanceMode;
  List<Map<String, dynamic>> get homeBanners => _homeBanners;

  ConfigProvider() {
    _loadLocal();
    _loadFromApi();
    _loadFx();
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
      _appDescription = (cfg['appDescription'] as String?)?.isNotEmpty == true
          ? cfg['appDescription'] as String
          : _appDescription;
      _appLogo = cfg['appLogo'] as String? ?? _appLogo;
      _maintenanceMode = cfg['maintenanceMode'] as bool? ?? _maintenanceMode;
      _categories = (cfg['categories'] as List? ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      _homeBanners = (cfg['banners'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _taxRate = double.tryParse(
              (cfg['feeInfo'] as Map<String, dynamic>?)?['vatPct']?.toString() ?? '') ??
          _taxRate;
      final feeInfo = cfg['feeInfo'] as Map<String, dynamic>?;
      if (feeInfo != null) {
        _deliveryBaseFee =
            ((num.tryParse('${feeInfo['deliveryBaseFeeCents']}')?.toDouble() ?? _deliveryBaseFee * 100)) / 100;
        _deliveryPerKm =
            ((num.tryParse('${feeInfo['deliveryPerKmCents']}')?.toDouble() ?? _deliveryPerKm * 100)) / 100;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Config api fetch error: $e');
    }
  }

  /// Loads the live USD->ZMW rate from GET /api/fx. The backend caches the
  /// rate for 6 hours and falls back to the last good rate, so this is cheap.
  Future<void> _loadFx() async {
    try {
      final res = await ApiClient.instance.get('/api/fx', withAuth: false);
      final fx = res as Map<String, dynamic>;
      final rate = double.tryParse(fx['usdToZmw']?.toString() ?? '');
      if (rate != null && rate > 0) {
        _usdToZmw = rate;
        _exchangeRate = 1 / rate;
        _fxSource = fx['source']?.toString() ?? '';
        _fxStale = fx['stale'] as bool? ?? false;
        final updated = fx['updatedAt']?.toString();
        _fxUpdatedAt = updated == null ? null : DateTime.tryParse(updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('FX fetch error: $e');
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
        'app_description': description,
        'app_logo': logo,
      });
    } catch (e) {
      debugPrint('Settings save to API failed: $e');
    }
  }

  /// Persists the maintenance flag to the server (admins only).
  /// The backend enforces it for every non-admin API call.
  Future<bool> setMaintenanceMode(bool on) async {
    try {
      await ApiClient.instance
          .patch('/api/admin/settings', body: {'maintenance_mode': on});
      _maintenanceMode = on;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Maintenance mode save failed: $e');
      return false;
    }
  }

  void refreshFx() => _loadFx();

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

  /// Drops a category after the server accepted `DELETE /api/admin/categories/:id`.
  void removeCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Re-reads branding, categories and banners from the API so admin writes
  /// show up on the storefront without restarting.
  Future<void> reload() => _loadFromApi();

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
