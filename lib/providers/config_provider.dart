import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        enabled: json['enabled'] as bool? ?? true,
      );
}

class ConfigProvider extends ChangeNotifier {
  final String tenantId = 'sell-on-app-default';
  String _appName = 'Sell On App';
  String _appSlogan = 'Premium Marketplace & Luxury Heritage';
  String _appDescription = 'A state-of-the-art retail platform for premium heritage products.';
  String _appLogo = '';

  String _currency = 'ZMW';
  String _theme = 'light';
  double _exchangeRate = 0.036;
  Timer? _exchangeRateTimer;

  List<Category> _categories = [
    Category(id: '1', name: 'Bags', icon: '👜'),
    Category(id: '2', name: 'Shoes', icon: '👠'),
    Category(id: '3', name: 'Jewelry', icon: '💍'),
    Category(id: '4', name: 'Dresses', icon: '👗'),
  ];

  double _taxRate = 16.0;
  bool _maintenanceMode = false;

  List<Map<String, dynamic>> _homeBanners = [
    {
      'id': '1',
      'title': 'New Collection',
      'subtitle': 'Premium Leather Bags',
      'image': 'https://placehold.co/600x400/F59E0B/FFFFFF?text=New+Collection',
      'link': '/product/1',
    },
    {
      'id': '2',
      'title': 'Summer Sale',
      'subtitle': 'Up to 50% Off',
      'image': 'https://placehold.co/600x400/D4AF37/FFFFFF?text=Summer+Sale',
      'link': '/product/2',
    },
  ];

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
    _loadConfig();
    _startExchangeRateSimulation();
  }

  @override
  void dispose() {
    _exchangeRateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfig() async {
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
      debugPrint('Config load error: $e');
    }
  }

  void _startExchangeRateSimulation() {
    _exchangeRateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final fluctuation = (Random().nextDouble() - 0.5) * 0.0005;
      _exchangeRate = double.parse((_exchangeRate + fluctuation).toStringAsFixed(5));
      notifyListeners();
    });
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
