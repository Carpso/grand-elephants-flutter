import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  List<Order> _orders = [];
  double _deliveryDistance = 0;
  String? _userId;

  double _cachedSubtotal = 0;
  double _cachedDeliveryFee = 0;
  double _cachedTotal = 0;
  int _cachedItemCount = 0;
  bool _isDirty = true;

  List<CartItem> get items => _items;
  List<Order> get orders => _orders;

  double get subtotal {
    if (_isDirty) _recompute();
    return _cachedSubtotal;
  }

  double get deliveryFee {
    if (_isDirty) _recompute();
    return _cachedDeliveryFee;
  }

  double get total {
    if (_isDirty) _recompute();
    return _cachedTotal;
  }

  int get itemCount {
    if (_isDirty) _recompute();
    return _cachedItemCount;
  }

  void _recompute() {
    _cachedSubtotal = _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
    _cachedDeliveryFee = _deliveryDistance > 0 ? 25.0 + (_deliveryDistance * 10.0) : 0.0;
    _cachedTotal = _cachedSubtotal + _cachedDeliveryFee;
    _cachedItemCount = _items.fold(0, (sum, item) => sum + item.quantity);
    _isDirty = false;
  }

  void _markDirty() {
    _isDirty = true;
    notifyListeners();
  }

  String get _cartKey => _userId != null ? '${StorageService.keyCart}_$_userId' : StorageService.keyCart;
  String get _orderKey => _userId != null ? 'orders_$_userId' : 'orders_guest';

  Future<void> loadForUser(String? uid) async {
    _userId = uid;
    final storedCart = await StorageService.get<List<dynamic>>(_cartKey);
    if (storedCart != null) {
      _items = storedCart
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final storedOrders = await StorageService.get<List<dynamic>>(_orderKey);
    if (storedOrders != null) {
      _orders = storedOrders
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persistCart() async {
    await StorageService.save(_cartKey, _items.map((e) => e.toJson()).toList());
  }

  Future<void> _persistOrders() async {
    await StorageService.save(_orderKey, _orders.map((e) => e.toJson()).toList());
  }

  void setDeliveryDistance(double km) {
    _deliveryDistance = km;
    _markDirty();
  }

  Future<void> addToCart(Product product) async {
    final existing = _items.indexWhere((item) => item.id == product.id);
    if (existing >= 0) {
      _items[existing] = _items[existing].copyWith(
        quantity: _items[existing].quantity + 1,
      );
    } else {
      _items.add(CartItem(
        id: product.id,
        name: product.name,
        price: product.price,
        image: product.image,
      ));
    }
    _markDirty();
    await _persistCart();
  }

  Future<void> addToCartWithQuantity(Product product, {int quantity = 1}) async {
    final existing = _items.indexWhere((item) => item.id == product.id);
    if (existing >= 0) {
      _items[existing] = _items[existing].copyWith(
        quantity: _items[existing].quantity + quantity,
      );
    } else {
      _items.add(CartItem(
        id: product.id,
        name: product.name,
        price: product.price,
        image: product.image,
        quantity: quantity,
      ));
    }
    _markDirty();
    await _persistCart();
  }

  Future<void> removeFromCart(String id) async {
    _items.removeWhere((item) => item.id == id);
    _markDirty();
    await _persistCart();
  }

  Future<void> clearCart() async {
    _items.clear();
    _markDirty();
    await _persistCart();
  }

  Future<void> placeOrder() async {
    if (_userId == null || _userId!.isEmpty) return;
    final newOrder = Order(
      id: Random().nextDouble().toString().substring(2, 11).toUpperCase(),
      items: List.from(_items),
      total: total,
      date: DateTime.now().toIso8601String(),
      status: 'Pending',
    );
    _orders.insert(0, newOrder);
    _items.clear();
    _isDirty = true;
    await _persistOrders();
    await _persistCart();
    try {
      final globalOrders = await StorageService.get<List<dynamic>>('global_orders') ?? [];
      globalOrders.insert(0, newOrder.toJson());
      await StorageService.save('global_orders', globalOrders);
    } catch (e) {
      debugPrint('Error persisting global orders: $e');
    }
    notifyListeners();
  }
}
