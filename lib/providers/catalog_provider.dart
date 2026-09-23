import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_client.dart';

class CatalogProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _banners = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  String? _category;

  List<Product> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get banners => _banners;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  String? get category => _category;

  Future<void> load({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final base = ApiClient.instance;
      final results = await Future.wait([
        base.get('/api/products', withAuth: false),
        base.get('/api/categories', withAuth: false),
        base.get('/api/config', withAuth: false),
      ]);
      final products = results[0] as List;
      final categories = results[1] as List;
      final config = results[2] as Map<String, dynamic>;
      _products = products
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      _categories = categories
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _banners = (config['banners'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      _error = '$e';
      debugPrint('Catalog load failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String q) async {
    _query = q.trim();
    notifyListeners();
    if (_query.isEmpty && _category == null) {
      await load();
      return;
    }
    try {
      final uri = Uri.parse('${ApiClient.instance.baseUrl}/api/products')
          .replace(queryParameters: {
        if (_query.isNotEmpty) 'q': _query,
        if (_category != null) 'category': _category,
      });
      final res = await ApiClient.instance.get(
          '${uri.path}?${uri.query}', withAuth: false);
      _products = (res as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '$e';
    }
    notifyListeners();
  }

  Future<void> filterByCategory(String? category) async {
    _category = category;
    notifyListeners();
    await search(_query);
  }

  Future<Product?> fetchProduct(String id) async {
    try {
      final res = await ApiClient.instance.get('/api/products/$id', withAuth: false);
      return Product.fromJson((res as Map<String, dynamic>)['product'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Product fetch failed: $e');
      return null;
    }
  }
}
