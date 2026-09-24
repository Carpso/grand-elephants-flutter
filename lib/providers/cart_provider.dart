import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';

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
        priceCents: product.priceCents,
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
        priceCents: product.priceCents,
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

  /// Places the order server-side (payment collected via Lipila server webhook).
  /// [tpin] is the optional buyer ZRA TPIN — exactly 10 digits, already
  /// normalised by the checkout screen.
  /// Returns the server order and clears the cart on success.
  Future<Order?> submitOrder({
    required String paymentMethod,
    required String deliveryAddress,
    required String deliveryMethod,
    double deliveryKm = 0,
    String? customerPhone,
    String? notes,
    String? tpin,
  }) async {
    if (_items.isEmpty) return null;

    final payload = {
      'items': _items
          .map((e) => {'productId': e.id, 'quantity': e.quantity})
          .toList(),
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'deliveryMethod': deliveryMethod,
      'deliveryKm': deliveryKm,
      'customerPhone': customerPhone ?? '',
      'notes': notes ?? '',
      if (tpin != null && tpin.isNotEmpty) 'tpin': tpin,
    };

    final res = await ApiClient.instance.post('/api/orders', body: payload);
    final json = res as Map<String, dynamic>;
    final order = Order.fromJson(json['order'] as Map<String, dynamic>);

    _orders.insert(0, order);
    _items.clear();
    _isDirty = true;
    await _persistOrders();
    await _persistCart();
    notifyListeners();
    return order;
  }

  /// Refreshes the order list from the server.
  Future<void> loadOrders() async {
    try {
      final res = await ApiClient.instance.get('/api/orders');
      _orders = (res as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      await _persistOrders();
      notifyListeners();
    } catch (e) {
      debugPrint('Order load failed: $e');
    }
  }

  /// Fetches a single order from the server.
  Future<Order?> fetchOrder(String orderId) async {
    try {
      final res = await ApiClient.instance.get('/api/orders/$orderId');
      final order =
          Order.fromJson((res as Map<String, dynamic>)['order'] as Map<String, dynamic>);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = order;
      } else {
        _orders.insert(0, order);
      }
      notifyListeners();
      return order;
    } catch (e) {
      debugPrint('Order fetch failed: $e');
      return null;
    }
  }

  /// Cancels a pending order on the server.
  Future<void> cancelOrder(String orderId) async {
    await ApiClient.instance.post('/api/orders/$orderId/cancel', body: {});
    await loadOrders();
  }

  // Admin/rider methods to update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0 && Order.validStatuses.contains(newStatus)) {
      _orders[index] = _orders[index].withStatus(newStatus);
      await _persistOrders();
      notifyListeners();

      // Also update global orders
      try {
        final globalOrders = await StorageService.get<List<dynamic>>('global_orders') ?? [];
        final globalIndex = globalOrders.indexWhere((o) => o['id'] == orderId);
        if (globalIndex >= 0) {
          globalOrders[globalIndex] = _orders[index].toJson();
          await StorageService.save('global_orders', globalOrders);
        }
      } catch (e) {
        debugPrint('Error updating global order status: $e');
      }
    }
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus, {String? transactionId, String? referenceId}) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      // Order model doesn't have a withPaymentStatus method, need to recreate
      final order = _orders[index];
      _orders[index] = Order(
        id: order.id,
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        total: order.total,
        date: order.date,
        status: order.status,
        paymentMethod: order.paymentMethod,
        paymentStatus: paymentStatus,
        transactionId: transactionId ?? order.transactionId,
        referenceId: referenceId ?? order.referenceId,
        deliveryAddress: order.deliveryAddress,
        deliveryMethod: order.deliveryMethod,
        customerPhone: order.customerPhone,
        notes: order.notes,
      );
      await _persistOrders();
      notifyListeners();
    }
  }
}