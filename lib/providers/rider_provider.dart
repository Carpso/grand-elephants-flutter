import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/api_client.dart';

class RiderDelivery {
  final String id;
  final Order order;
  final String businessName;
  final String deliveryAddress;
  final String customerPhone;

  const RiderDelivery({
    required this.id,
    required this.order,
    required this.businessName,
    required this.deliveryAddress,
    required this.customerPhone,
  });
}

class RiderProfile {
  final String id;
  final String businessId;
  final String businessName;
  final String name;
  final String phone;
  final String vehicle;
  final String status;
  final double balance;
  final int balanceCents;
  final String joined;

  const RiderProfile({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.status,
    required this.balance,
    required this.balanceCents,
    required this.joined,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) => RiderProfile(
        id: '${json['id']}',
        businessId: '${json['businessId'] ?? ''}',
        businessName: json['businessName'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        vehicle: json['vehicle'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        balanceCents: (json['balanceCents'] as num?)?.toInt() ?? 0,
        joined: json['joined'] as String? ?? '',
      );
}

class RiderPayout {
  final String id;
  final double amount;
  final double fee;
  final double net;
  final String status;
  final String createdAt;
  final String? error;

  const RiderPayout({
    required this.id,
    required this.amount,
    required this.fee,
    required this.net,
    required this.status,
    required this.createdAt,
    this.error,
  });

  factory RiderPayout.fromJson(Map<String, dynamic> json) => RiderPayout(
        id: '${json['id']}',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
        net: (json['net'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'processing',
        createdAt: json['createdAt'] as String? ?? '',
        error: json['error'] as String?,
      );
}

class RiderProvider extends ChangeNotifier {
  List<RiderProfile> _profiles = [];
  List<Order> _deliveries = [];
  List<RiderPayout> _payouts = [];
  bool _loading = false;
  String? _error;

  List<RiderProfile> get profiles => _profiles;
  List<Order> get deliveries => _deliveries;
  List<RiderPayout> get payouts => _payouts;
  bool get loading => _loading;
  String? get error => _error;
  double get balance => _profiles.isEmpty ? 0 : _profiles.first.balance;
  bool get isApproved => _profiles.any((p) => p.status == 'approved');

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final base = ApiClient.instance;
      final results = await Future.wait([
        base.get('/api/riders/me'),
        base.get('/api/riders/me/deliveries'),
        base.get('/api/riders/me/payouts'),
      ]);
      _profiles = (results[0] as List)
          .map((e) => RiderProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      _deliveries = (results[1] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      _payouts = (results[2] as List)
          .map((e) => RiderPayout.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '$e';
      debugPrint('Rider load failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDeliveries() async {
    try {
      final res = await ApiClient.instance.get('/api/riders/me/deliveries');
      _deliveries = (res as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  /// Server accepts `Out for Delivery` / `Delivered` only, plus an optional
  /// `proofPhoto` (data URI) stored on the order.
  Future<void> updateOrderStatus(String orderId, String status,
      {String? proofPhoto}) async {
    try {
      await ApiClient.instance.post('/api/orders/$orderId/rider-status',
          body: {
            'status': status,
            if (proofPhoto != null && proofPhoto.isNotEmpty)
              'proofPhoto': proofPhoto,
          });
      await loadDeliveries();
      await load();
    } catch (e) {
      debugPrint('Rider status update failed: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(double lat, double lng, {String address = ''}) async {
    try {
      await ApiClient.instance.post('/api/riders/me/location',
          body: {'lat': lat, 'lng': lng, 'address': address});
    } catch (e) {
      debugPrint('Location update failed: $e');
    }
  }
}