import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class WishlistProvider extends ChangeNotifier {
  List<Product> _wishlist = [];

  List<Product> get wishlist => _wishlist;

  WishlistProvider() {
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final stored = await StorageService.get<List<dynamic>>(StorageService.keyWishlist);
    if (stored != null) {
      _wishlist = stored
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    await StorageService.save(
      StorageService.keyWishlist,
      _wishlist.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> addToWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
      return;
    }
    _wishlist.add(product);
    notifyListeners();
    await _persist();
  }

  Future<void> removeFromWishlist(String productId) async {
    _wishlist.removeWhere((item) => item.id == productId);
    notifyListeners();
    await _persist();
  }

  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item.id == productId);
  }

  Future<void> clearWishlist() async {
    _wishlist.clear();
    notifyListeners();
    await _persist();
  }
}
