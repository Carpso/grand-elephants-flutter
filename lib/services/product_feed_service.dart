import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_client.dart';

/// Curated product feeds used by the home merchandising rows.
/// Every endpoint returns the same JSON shape as `GET /api/products`.
class ProductFeedService {
  const ProductFeedService._();

  static Future<List<Product>> _fetch(String path, {int limit = 12}) async {
    final res = await ApiClient.instance.get('$path?limit=$limit', withAuth: false);
    return (res as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Product>> newArrivals({int limit = 12}) =>
      _fetch('/api/products/new', limit: limit);

  static Future<List<Product>> trending({int limit = 12}) =>
      _fetch('/api/products/trending', limit: limit);

  static Future<List<Product>> suggested({int limit = 12}) =>
      _fetch('/api/products/suggested', limit: limit);

  /// Loads all three feeds independently — a failing feed never hides the
  /// others, and failures resolve to an empty list (row is simply hidden).
  static Future<Map<String, List<Product>>> loadAll({int limit = 12}) async {
    Future<List<Product>> guard(String feed, Future<List<Product>> call) =>
        call.catchError((e) {
          debugPrint('Product feed "$feed" failed: $e');
          return <Product>[];
        });

    final results = await Future.wait([
      guard('new', newArrivals(limit: limit)),
      guard('trending', trending(limit: limit)),
      guard('suggested', suggested(limit: limit)),
    ]);
    return {
      'new': results[0],
      'trending': results[1],
      'suggested': results[2],
    };
  }
}
