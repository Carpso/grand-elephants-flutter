import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AdminStats {
  final int users;
  final int businesses;
  final int orders;
  final int products;
  final int pendingBusinesses;
  final int pendingPayouts;
  final int gmvCents;
  final int businessWalletCents;
  final int platformCommissionCents;

  const AdminStats({
    this.users = 0,
    this.businesses = 0,
    this.orders = 0,
    this.products = 0,
    this.pendingBusinesses = 0,
    this.pendingPayouts = 0,
    this.gmvCents = 0,
    this.businessWalletCents = 0,
    this.platformCommissionCents = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        users: (json['users'] as num?)?.toInt() ?? 0,
        businesses: (json['businesses'] as num?)?.toInt() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        products: (json['products'] as num?)?.toInt() ?? 0,
        pendingBusinesses: (json['pendingBusinesses'] as num?)?.toInt() ?? 0,
        pendingPayouts: (json['pendingPayouts'] as num?)?.toInt() ?? 0,
        gmvCents: (json['gmvCents'] as num?)?.toInt() ?? 0,
        businessWalletCents: (json['businessWalletCents'] as num?)?.toInt() ?? 0,
        platformCommissionCents: (json['platformCommissionCents'] as num?)?.toInt() ?? 0,
      );
}

class AdminRider {
  final String id;
  final String userId;
  final String businessId;
  final String businessName;
  final String name;
  final String phone;
  final String vehicle;
  final String status;
  final double balance;
  final int balanceCents;
  final String joined;

  const AdminRider({
    required this.id,
    required this.userId,
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

  factory AdminRider.fromJson(Map<String, dynamic> json) => AdminRider(
        id: '${json['id']}',
        userId: '${json['userId'] ?? ''}',
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

class AdminPayout {
  final String id;
  final String businessId;
  final String businessName;
  final String riderName;
  final double amount;
  final int amountCents;
  final int feeCents;
  final int netCents;
  final String phone;
  final String network;
  final String status;
  final String createdAt;
  final String? error;

  const AdminPayout({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.riderName = '',
    required this.amount,
    required this.amountCents,
    required this.feeCents,
    required this.netCents,
    required this.phone,
    required this.network,
    required this.status,
    required this.createdAt,
    this.error,
  });

  factory AdminPayout.fromJson(Map<String, dynamic> json) => AdminPayout(
        id: '${json['id']}',
        businessId: '${json['businessId'] ?? ''}',
        businessName: json['businessName'] as String? ?? '',
        riderName: json['riderName'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
        feeCents: (json['feeCents'] as num?)?.toInt() ?? 0,
        netCents: (json['netCents'] as num?)?.toInt() ?? 0,
        phone: json['phone'] as String? ?? '',
        network: json['network'] as String? ?? 'mtn',
        status: json['status'] as String? ?? 'processing',
        createdAt: json['createdAt'] as String? ?? '',
        error: json['error'] as String?,
      );
}

class AdminProvider extends ChangeNotifier {
  AdminStats _stats = const AdminStats();
  List<User> _users = [];
  List<AdminRider> _riders = [];
  List<AdminPayout> _payouts = [];
  List<Map<String, dynamic>> _riderApplications = [];
  List<Order> _orders = [];
  List<Product> _products = [];
  bool _loading = false;
  String? _error;
  double? _lipilaBalance;
  int _businessWalletCents = 0;

  AdminStats get stats => _stats;
  List<User> get users => _users;
  List<AdminRider> get riders => _riders;
  List<AdminPayout> get payouts => _payouts;
  List<Map<String, dynamic>> get riderApplications => _riderApplications;
  List<Order> get orders => _orders;
  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;
  double? get lipilaBalance => _lipilaBalance;
  int get businessWalletCents => _businessWalletCents;

  Future<void> loadStats() async {
    try {
      final res = await ApiClient.instance.get('/api/admin/stats');
      _stats = AdminStats.fromJson(res as Map<String, dynamic>);
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> loadRiders() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/admin/riders'),
        ApiClient.instance.get('/api/admin/rider-applications'),
        ApiClient.instance.get('/api/admin/rider-payouts'),
      ]);
      _riders = (results[0] as List)
          .map((e) => AdminRider.fromJson(e as Map<String, dynamic>))
          .toList();
      _riderApplications = (results[1] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _payouts = (results[2] as List)
          .map((e) => AdminPayout.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> loadOrders({String? status}) async {
    try {
      final res = await ApiClient.instance
          .get(status == null ? '/api/admin/orders' : '/api/admin/orders?status=$status');
      _orders = (res as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> loadUsers() async {
    try {
      final res = await ApiClient.instance.get('/api/admin/users');
      _users = (res as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> loadProducts() async {
    try {
      final res = await ApiClient.instance.get('/api/businesses/me/products');
      _products = (res as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> loadLipilaBalance() async {
    try {
      final res = await ApiClient.instance.get('/api/admin/lipila/balance');
      final data = res as Map<String, dynamic>;
      _lipilaBalance = (data['lipilaBalance'] as num?)?.toDouble() ?? 0;
      _businessWalletCents = (data['businessWalletCents'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> approveRiderApplication(String userId, {String? businessId, String vehicle = ''}) async {
    try {
      await ApiClient.instance.post('/api/admin/rider-applications/$userId/approve',
          body: {if (businessId != null) 'businessId': businessId, 'vehicle': vehicle});
      await loadRiders();
    } catch (e) {
      debugPrint('Approve rider failed: $e');
      rethrow;
    }
  }

  Future<void> setRiderStatus(String riderId, String status) async {
    try {
      await ApiClient.instance.post('/api/admin/riders/$riderId/status', body: {'status': status});
      await loadRiders();
    } catch (e) {
      debugPrint('Set rider status failed: $e');
      rethrow;
    }
  }

  Future<void> payRider(String riderId) async {
    try {
      await ApiClient.instance.post('/api/admin/riders/$riderId/payout', body: {});
      await loadRiders();
    } catch (e) {
      debugPrint('Pay rider failed: $e');
      rethrow;
    }
  }

  Future<void> processPayout(String payoutId) async {
    try {
      await ApiClient.instance.post('/api/admin/payouts/$payoutId/process', body: {});
      await loadRiders();
    } catch (e) {
      debugPrint('Process payout failed: $e');
    }
  }

  Future<void> updateUser(String userId, {String? role, String? riderStatus}) async {
    try {
      await ApiClient.instance.patch('/api/admin/users/$userId', body: {
        if (role != null) 'role': role,
        if (riderStatus != null) 'riderStatus': riderStatus,
      });
      await loadUsers();
    } catch (e) {
      debugPrint('Update user failed: $e');
      rethrow;
    }
  }

  Future<void> refreshAll() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([loadStats(), loadRiders(), loadOrders(), loadUsers()]);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}