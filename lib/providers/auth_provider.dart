import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String _role = 'user';
  String _riderStatus = 'none';
  bool _isLoading = true;

  Timer? _sessionTimer;
  static const _sessionTimeout = Duration(minutes: 60);

  User? get user => _user;
  String get role => _role;
  String get riderStatus => _riderStatus;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final data = await StorageService.get<Map<String, dynamic>>(StorageService.keyUser);
      if (data != null) {
        _user = User.fromJson(data);
        _role = _user!.role;
        _riderStatus = _user!.riderStatus;
        _startSessionTimer();
        _refreshProfile();
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshProfile() async {
    try {
      final res = await ApiClient.instance.get('/api/me');
      final json = (res as Map<String, dynamic>)['user'] as Map<String, dynamic>;
      _user = User.fromJson(json);
      _role = _user!.role;
      _riderStatus = _user!.riderStatus;
      await StorageService.save(StorageService.keyUser, _user!.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Profile refresh failed: $e');
    }
  }

  void resetSession() {
    _sessionTimer?.cancel();
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      if (_user == null) return;
      debugPrint('Session expired after 60 minutes of inactivity');
      logout();
    });
  }

  Future<void> requestOtp(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiClient.instance.post('/api/auth/request-otp', body: {'phone': phone}, withAuth: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies the OTP and stores the session. Returns the fresh user.
  Future<User> verifyOtp(String phone, String code, {String? name, String? email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.instance.post(
        '/api/auth/verify-otp',
        body: {
          'phone': phone,
          'code': code,
          if (name != null && name.isNotEmpty) 'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        },
        withAuth: false,
      );
      final json = res as Map<String, dynamic>;
      final token = json['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const ApiException('No session returned by server');
      }
      await ApiClient.instance.setToken(token);
      _user = User.fromJson(json['user'] as Map<String, dynamic>);
      _role = _user!.role;
      _riderStatus = _user!.riderStatus;
      await StorageService.save(StorageService.keyUser, _user!.toJson());
      _startSessionTimer();
      notifyListeners();
      return _user!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _sessionTimer?.cancel();
    _isLoading = true;
    notifyListeners();
    try {
      await ApiClient.instance.setToken(null);
      await StorageService.remove(StorageService.keyUser);
      _user = null;
      _role = 'user';
      _riderStatus = 'none';
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (_user == null) return;
    try {
      final res = await ApiClient.instance.patch('/api/me', body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      _user = User.fromJson((res as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      _role = _user!.role;
      _riderStatus = _user!.riderStatus;
      await StorageService.save(StorageService.keyUser, _user!.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Profile update failed: $e');
      rethrow;
    }
  }

  Future<void> requestRiderAccess(Map<String, dynamic> details) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await ApiClient.instance.post('/api/riders/apply', body: {
        'name': _user!.name,
        'phone': _user!.phone,
        'vehicle': details['vehicleType'] as String? ?? details['vehicle'] as String? ?? '',
        'bikePhoto': details['bikePhoto'] as String?,
      });
      _riderStatus = 'pending';
      _user = _user!.copyWith(riderStatus: 'pending', bikePhoto: details['bikePhoto'] as String?);
      await StorageService.save(StorageService.keyUser, _user!.toJson());
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
